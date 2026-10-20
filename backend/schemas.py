from pydantic import BaseModel

class UsuarioCreate(BaseModel):
    nome: str
    email: str | None = None
    ativo: bool = True

class UsuarioUpdate(BaseModel):
    # Todos opcionais: só os campos enviados na requisição serão alterados
    nome: str | None = None
    email: str | None = None
    ativo: bool | None = None

class UsuarioOut(BaseModel):
    id: int
    nome: str
    email: str | None
    ativo: bool

    class Config:
        from_attributes = True

class DigitalCreate(BaseModel):
    usuario_id: int
    template_id: int

class DigitalOut(BaseModel):
    id: int
    usuario_id: int
    template_id: int

    class Config:
        from_attributes = True

class AcessoCreate(BaseModel):
    dispositivo_id: int
    template_id_lido: int

class AcessoOut(BaseModel):
    id: int
    usuario_id: int | None
    dispositivo_id: int
    template_id_lido: int | None
    resultado: str

    class Config:
        from_attributes = True

class DispositivoCreate(BaseModel):
    nome: str
    local: str | None = None
    ativo: bool = True

class DispositivoOut(BaseModel):
    id: int
    nome: str
    local: str | None
    ativo: bool

    class Config:
        from_attributes = True

class DispositivoComChave(DispositivoOut):
    # Usado só na criação do dispositivo e na geração de nova chave.
    # A chave aparece uma única vez: depois disso só o hash fica guardado.
    api_key: str