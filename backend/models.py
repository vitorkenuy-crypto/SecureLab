from sqlalchemy import Column, Integer, String, Boolean, TIMESTAMP, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

class Usuario(Base):
    __tablename__ = "usuario"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(100), nullable=False)
    email = Column(String(150), unique=True)
    ativo = Column(Boolean, default=True)
    criado_em = Column(TIMESTAMP, server_default=func.now())

    digitais = relationship("Digital", back_populates="usuario")
    acessos = relationship("Acesso", back_populates="usuario")


class Dispositivo(Base):
    __tablename__ = "dispositivo"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(100), nullable=False)
    local = Column(String(100))
    ativo = Column(Boolean, default=True)
    api_key_hash = Column(String(64))  # SHA-256 da chave de API do dispositivo (nunca a chave em si)

    acessos = relationship("Acesso", back_populates="dispositivo")


class Digital(Base):
    __tablename__ = "digital"

    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuario.id"), nullable=False)
    template_id = Column(Integer, nullable=False, unique=True)
    cadastrada_em = Column(TIMESTAMP, server_default=func.now())

    usuario = relationship("Usuario", back_populates="digitais")


class Acesso(Base):
    __tablename__ = "acesso"

    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuario.id"), nullable=True)
    dispositivo_id = Column(Integer, ForeignKey("dispositivo.id"), nullable=False)
    template_id_lido = Column(Integer, nullable=True)
    data_hora = Column(TIMESTAMP, server_default=func.now())
    resultado = Column(String(20), nullable=False)

    __table_args__ = (
        CheckConstraint("resultado IN ('AUTORIZADO', 'NEGADO')", name="check_resultado"),
    )

    usuario = relationship("Usuario", back_populates="acessos")
    dispositivo = relationship("Dispositivo", back_populates="acessos")