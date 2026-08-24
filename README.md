# SecureLab - Sistema Inteligente de Controle de Acesso Biométrico

[![Status do Projeto](https://img.shields.io/badge/Status-Em%20Desenvolvimento%20(MVP)-yellow)](#)
[![Estrutura](https://img.shields.io/badge/Arquitetura-Monorepo-blue)](#)
[![Hardware](https://img.shields.io/badge/Hardware-ESP32%20%7C%20R307-green)](#)
[![Backend](https://img.shields.io/badge/Backend-FastAPI%20%7C%20PostgreSQL-darkblue)](#)
[![Mobile](https://img.shields.io/badge/Mobile-Flutter-02569B)](#)

O **SecureLab** é uma solução completa de controle de acesso físico e digital desenvolvida no âmbito do Projeto Integrador do curso de Sistemas de Informação. O sistema integra hardware embarcado (**ESP32** e sensor biométrico óptico **R307/R307S**), atuadores de acionamento (módulo relé e fechadura solenoide 12V), uma API RESTful de alta performance em **FastAPI**, persistência e auditoria em banco de dados relacional **PostgreSQL**, e uma interface administrativa mobile em **Flutter**.

---

## Objetivo do Projeto

Construir uma arquitetura integrada de ponta a ponta que elimine o uso de chaves físicas e cadastros descentralizados, garantindo que o acesso a ambientes controlados ocorra por meio de biometria validada em tempo real, com registro auditável de todas as tentativas (autorizadas ou negadas) e gestão centralizada via aplicativo mobile.

---

## Fluxo de Funcionamento e Lógica de Acesso
