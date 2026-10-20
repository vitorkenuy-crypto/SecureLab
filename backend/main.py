from datetime import date, timedelta
from typing import Literal
from fastapi import FastAPI, Depends, HTTPException, Query, Response, Header
from sqlalchemy.orm import Session, joinedload
from sqlalchemy.exc import IntegrityError
from database import get_db
import models
import schemas
import os
from fastapi.security import OAuth2PasswordRequestForm
from security import verificar_senha, criar_token, get_current_admin, gerar_api_key, verificar_api_key

ADMIN_USERNAME = os.getenv("ADMIN_USERNAME")
ADMIN_PASSWORD_HASH = os.getenv("ADMIN_PASSWORD_HASH")

app = FastAPI(title="SecureLab API")

@app.post("/auth/login")
def login(form_data: OAuth2PasswordRequestForm = Depends()):
    if form_data.username != ADMIN_USERNAME or not verificar_senha(form_data.password, ADMIN_PASSWORD_HASH):
        raise HTTPException(status_code=401, detail="Usuário ou senha incorretos")
    token = criar_token({"sub": form_data.username})
    return {"access_token": token, "token_type": "bearer"}


@app.get("/")
def raiz():
    return {"mensagem": "SecureLab API rodando com sucesso"}

@app.get("/usuarios")
def listar_usuarios(db: Session = Depends(get_db), current_admin: str = Depends(get_current_admin)):
    usuarios = db.query(models.Usuario).all()
    return [
        {"id": u.id, "nome": u.nome, "email": u.email, "ativo": u.ativo}
        for u in usuarios
    ]

@app.post("/usuarios", response_model=schemas.UsuarioOut)
def criar_usuario(usuario: schemas.UsuarioCreate, db: Session = Depends(get_db), current_admin: str = Depends(get_current_admin)):
    # Verifica antes se o e-mail já está em uso (só quando um e-mail foi informado)
    if usuario.email:
        email_existente = db.query(models.Usuario).filter(models.Usuario.email == usuario.email).first()
        if email_existente:
            raise HTTPException(status_code=409, detail="Já existe um usuário cadastrado com esse e-mail")

    novo_usuario = models.Usuario(
        nome=usuario.nome,
        email=usuario.email,
        ativo=usuario.ativo,
    )
    db.add(novo_usuario)
    try:
        db.commit()
    except IntegrityError:
        # Rede de segurança: duas requisições simultâneas podem passar pela checagem acima
        db.rollback()
        raise HTTPException(status_code=409, detail="Já existe um usuário cadastrado com esse e-mail")
    db.refresh(novo_usuario)
    return novo_usuario

@app.post("/digitais", response_model=schemas.DigitalOut)
def cadastrar_digital(digital: schemas.DigitalCreate, db: Session = Depends(get_db), current_admin: str = Depends(get_current_admin)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id == digital.usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")

    # Verifica antes se o template_id já está em uso por outra digital
    template_existente = db.query(models.Digital).filter(
        models.Digital.template_id == digital.template_id
    ).first()
    if template_existente:
        raise HTTPException(status_code=409, detail="Esse template_id já está cadastrado em outra digital")

    nova_digital = models.Digital(
        usuario_id=digital.usuario_id,
        template_id=digital.template_id,
    )
    db.add(nova_digital)
    try:
        db.commit()
    except IntegrityError:
        # Rede de segurança contra requisições simultâneas
        db.rollback()
        raise HTTPException(status_code=409, detail="Esse template_id já está cadastrado em outra digital")
    db.refresh(nova_digital)
    return nova_digital

@app.get("/digitais", response_model=list[schemas.DigitalOut])
def listar_digitais(usuario_id: int | None = None, db: Session = Depends(get_db), current_admin: str = Depends(get_current_admin)):
    # Filtro opcional: GET /digitais?usuario_id=1 lista só as digitais desse usuário
    consulta = db.query(models.Digital)
    if usuario_id is not None:
        consulta = consulta.filter(models.Digital.usuario_id == usuario_id)
    return consulta.order_by(models.Digital.id).all()

@app.delete("/digitais/{digital_id}", response_model=schemas.DigitalOut)
def remover_digital(digital_id: int, db: Session = Depends(get_db), current_admin: str = Depends(get_current_admin)):
    digital = db.query(models.Digital).filter(models.Digital.id == digital_id).first()
    if not digital:
        raise HTTPException(status_code=404, detail="Digital não encontrada")

    # Remoção definitiva: o histórico em "acesso" guarda usuario_id e template_id_lido,
    # não o id da digital, então nenhum registro de acesso é perdido.
    removida = schemas.DigitalOut.model_validate(digital)
    db.delete(digital)
    db.commit()
    return removida

# Esta rota NÃO usa token de admin (o ESP32 não faz login). Quem chama se identifica
# com a chave de API do próprio dispositivo, enviada no header X-API-Key.
@app.post("/acessos", response_model=schemas.AcessoOut)
def registrar_acesso(
    acesso: schemas.AcessoCreate,
    x_api_key: str | None = Header(default=None),
    db: Session = Depends(get_db),
):
    dispositivo = db.query(models.Dispositivo).filter(
        models.Dispositivo.id == acesso.dispositivo_id
    ).first()

    # 1. Autentica o dispositivo. A resposta é a mesma para "dispositivo não existe" e
    #    "chave errada", para não revelar a quem está de fora quais ids existem.
    if not dispositivo or not verificar_api_key(x_api_key, dispositivo.api_key_hash):
        raise HTTPException(status_code=401, detail="Dispositivo ou chave de API inválidos")

    usuario_id = None
    resultado = "NEGADO"

    # 2. Dispositivo desativado nunca autoriza ninguém (a tentativa ainda é registrada abaixo)
    if dispositivo.ativo:
        # 3. Procura uma digital cadastrada com esse template_id
        digital = db.query(models.Digital).filter(
            models.Digital.template_id == acesso.template_id_lido
        ).first()

        if digital:
            # 4. Se achou a digital, verifica se o usuário dono dela está ativo
            usuario = db.query(models.Usuario).filter(
                models.Usuario.id == digital.usuario_id
            ).first()

            if usuario and usuario.ativo:
                usuario_id = usuario.id
                resultado = "AUTORIZADO"

    # 5. Registra a tentativa, autorizada ou não
    novo_acesso = models.Acesso(
        usuario_id=usuario_id,
        dispositivo_id=acesso.dispositivo_id,
        template_id_lido=acesso.template_id_lido,
        resultado=resultado,
    )
    db.add(novo_acesso)
    db.commit()
    db.refresh(novo_acesso)
    return novo_acesso

@app.post("/dispositivos", response_model=schemas.DispositivoComChave)
def criar_dispositivo(dispositivo: schemas.DispositivoCreate, db: Session = Depends(get_db), current_admin: str = Depends(get_current_admin)):
    chave, chave_hash = gerar_api_key()
    novo_dispositivo = models.Dispositivo(
        nome=dispositivo.nome,
        local=dispositivo.local,
        ativo=dispositivo.ativo,
        api_key_hash=chave_hash,
    )
    db.add(novo_dispositivo)
    db.commit()
    db.refresh(novo_dispositivo)
    # A chave em texto só é mostrada agora. Anote-a: depois só o hash existe no banco.
    return {**schemas.DispositivoOut.model_validate(novo_dispositivo).model_dump(), "api_key": chave}

@app.post("/dispositivos/{dispositivo_id}/chave", response_model=schemas.DispositivoComChave)
def gerar_nova_chave(dispositivo_id: int, db: Session = Depends(get_db), current_admin: str = Depends(get_current_admin)):
    # Serve para dispositivos já existentes (que ainda não têm chave) e para trocar
    # a chave de um dispositivo se ela vazar. A chave antiga deixa de funcionar na hora.
    dispositivo = db.query(models.Dispositivo).filter(models.Dispositivo.id == dispositivo_id).first()
    if not dispositivo:
        raise HTTPException(status_code=404, detail="Dispositivo não encontrado")

    chave, chave_hash = gerar_api_key()
    dispositivo.api_key_hash = chave_hash
    db.commit()
    db.refresh(dispositivo)
    return {**schemas.DispositivoOut.model_validate(dispositivo).model_dump(), "api_key": chave}

@app.get("/dispositivos")
def listar_dispositivos(db: Session = Depends(get_db), current_admin: str = Depends(get_current_admin)):
    dispositivos = db.query(models.Dispositivo).all()
    return [
        {"id": d.id, "nome": d.nome, "local": d.local, "ativo": d.ativo}
        for d in dispositivos
    ]

@app.get("/acessos")
def listar_acessos(
    response: Response,
    limit: int = Query(50, ge=1, le=500, description="Quantos registros devolver (máx. 500)"),
    offset: int = Query(0, ge=0, description="Quantos registros pular (para paginar)"),
    usuario_id: int | None = None,
    dispositivo_id: int | None = None,
    resultado: Literal["AUTORIZADO", "NEGADO"] | None = None,
    data_inicio: date | None = Query(None, description="Formato AAAA-MM-DD, inclusive"),
    data_fim: date | None = Query(None, description="Formato AAAA-MM-DD, inclusive"),
    db: Session = Depends(get_db),
    current_admin: str = Depends(get_current_admin),
):
    consulta = db.query(models.Acesso)

    if usuario_id is not None:
        consulta = consulta.filter(models.Acesso.usuario_id == usuario_id)
    if dispositivo_id is not None:
        consulta = consulta.filter(models.Acesso.dispositivo_id == dispositivo_id)
    if resultado is not None:
        consulta = consulta.filter(models.Acesso.resultado == resultado)
    if data_inicio is not None:
        consulta = consulta.filter(models.Acesso.data_hora >= data_inicio)
    if data_fim is not None:
        # data_fim é inclusiva: vai até o fim desse dia (antes da meia-noite do dia seguinte)
        consulta = consulta.filter(models.Acesso.data_hora < data_fim + timedelta(days=1))

    # Total com os filtros aplicados (antes de limit/offset), devolvido num header
    # para o app saber quantas páginas existem sem mudar o formato da resposta.
    response.headers["X-Total-Count"] = str(consulta.count())

    acessos = (
        consulta
        .options(joinedload(models.Acesso.usuario), joinedload(models.Acesso.dispositivo))
        .order_by(models.Acesso.data_hora.desc(), models.Acesso.id.desc())
        .limit(limit)
        .offset(offset)
        .all()
    )
    return [
        {
            "id": a.id,
            "usuario_id": a.usuario_id,
            "usuario_nome": a.usuario.nome if a.usuario else None,
            "dispositivo_id": a.dispositivo_id,
            "dispositivo_nome": a.dispositivo.nome,
            "template_id_lido": a.template_id_lido,
            "data_hora": a.data_hora,
            "resultado": a.resultado,
        }
        for a in acessos
    ]

@app.delete("/usuarios/{usuario_id}", response_model=schemas.UsuarioOut)
def remover_usuario(usuario_id: int, db: Session = Depends(get_db), current_admin: str = Depends(get_current_admin)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")

    usuario.ativo = False
    db.commit()
    db.refresh(usuario)
    return usuario

@app.get("/usuarios/{usuario_id}", response_model=schemas.UsuarioOut)
def buscar_usuario(usuario_id: int, db: Session = Depends(get_db), current_admin: str = Depends(get_current_admin)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    return usuario

@app.patch("/usuarios/{usuario_id}", response_model=schemas.UsuarioOut)
def atualizar_usuario(usuario_id: int, dados: schemas.UsuarioUpdate, db: Session = Depends(get_db), current_admin: str = Depends(get_current_admin)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")

    # Só os campos que vieram na requisição (o que não foi enviado não é tocado)
    campos = dados.model_dump(exclude_unset=True)

    # nome e ativo são obrigatórios no banco: não aceitam null
    for campo in ("nome", "ativo"):
        if campo in campos and campos[campo] is None:
            raise HTTPException(status_code=400, detail=f"O campo '{campo}' não pode ser nulo")

    # E-mail novo não pode já pertencer a outro usuário
    novo_email = campos.get("email")
    if novo_email and novo_email != usuario.email:
        email_existente = db.query(models.Usuario).filter(
            models.Usuario.email == novo_email,
            models.Usuario.id != usuario_id,
        ).first()
        if email_existente:
            raise HTTPException(status_code=409, detail="Já existe um usuário cadastrado com esse e-mail")

    for campo, valor in campos.items():
        setattr(usuario, campo, valor)

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Já existe um usuário cadastrado com esse e-mail")
    db.refresh(usuario)
    return usuario