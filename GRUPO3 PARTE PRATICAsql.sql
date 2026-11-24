
BEGIN
  FOR s IN (SELECT column_value AS n FROM TABLE(sys.odcivarchar2list(
      'CATEGORIA_UTILIZADOR','TIPO_VEICULO','CATEGORIA_VAGA','METODO_PAGAMENTO',
      'TIPO_OCORRENCIA','PERFIL_ACESSO','UTILIZADOR','CONTACTO_UTILIZADOR',
      'FUNCIONARIO','CONTA_ACESSO','UTILIZADOR_VIATURA','ESTACIONAMENTO',
      'PISO_AREA','ZONA','VAGA','PONTO_ACESSO','TARIFA','RESERVA','UTILIZACAO',
      'AJUSTE_COBRANCA','PAGAMENTO','OCORRENCIA','MEDIDA_OCORRENCIA',
      'NOTIFICACAO','AUDITORIA'))) LOOP
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_' || s.n || ' START WITH 1 INCREMENT BY 1 NOCACHE';
  END LOOP;
END;
/


CREATE TABLE categoria_utilizador (
  cod_categoria_utilizador NUMBER(3)    DEFAULT seq_categoria_utilizador.NEXTVAL PRIMARY KEY,
  designacao               VARCHAR2(40) NOT NULL UNIQUE,
  sujeito_pagamento        CHAR(1)      NOT NULL CHECK (sujeito_pagamento IN ('S','N'))
);

CREATE TABLE tipo_veiculo (
  cod_tipo_veiculo NUMBER(2)     DEFAULT seq_tipo_veiculo.NEXTVAL PRIMARY KEY,
  designacao       VARCHAR2(30)  NOT NULL UNIQUE,
  descricao        VARCHAR2(100)
);

CREATE TABLE categoria_vaga (
  cod_categoria_vaga NUMBER(3)     DEFAULT seq_categoria_vaga.NEXTVAL PRIMARY KEY,
  designacao         VARCHAR2(40)  NOT NULL UNIQUE,
  descricao          VARCHAR2(150)
);

CREATE TABLE metodo_pagamento (
  cod_metodo_pagamento NUMBER(2)    DEFAULT seq_metodo_pagamento.NEXTVAL PRIMARY KEY,
  designacao           VARCHAR2(40) NOT NULL UNIQUE
);

CREATE TABLE tipo_ocorrencia (
  cod_tipo_ocorrencia NUMBER(3)    DEFAULT seq_tipo_ocorrencia.NEXTVAL PRIMARY KEY,
  designacao          VARCHAR2(40) NOT NULL UNIQUE
);

CREATE TABLE perfil_acesso (
  cod_perfil NUMBER(2)     DEFAULT seq_perfil_acesso.NEXTVAL PRIMARY KEY,
  designacao VARCHAR2(30)  NOT NULL UNIQUE
             CHECK (designacao IN ('ADMINISTRADOR','OPERADOR','FINANCEIRO','SEGURANCA','UTILIZADOR')),
  descricao  VARCHAR2(150)
);

CREATE TABLE utilizador (
  cod_utilizador           NUMBER(6)    DEFAULT seq_utilizador.NEXTVAL PRIMARY KEY,
  nome_completo            VARCHAR2(120) NOT NULL,
  tipo_documento           VARCHAR2(25)  NOT NULL,
  numero_documento         VARCHAR2(30)  NOT NULL,
  cod_categoria_utilizador NUMBER(3)     NOT NULL REFERENCES categoria_utilizador,
  estado                   VARCHAR2(10)  DEFAULT 'ACTIVO' NOT NULL
                           CHECK (estado IN ('ACTIVO','INACTIVO','SUSPENSO')),
  data_registo             DATE          DEFAULT SYSDATE NOT NULL,
  CONSTRAINT uq_utilizador_documento UNIQUE (tipo_documento, numero_documento)
);

CREATE TABLE contacto_utilizador (
  cod_contacto   NUMBER(8)     DEFAULT seq_contacto_utilizador.NEXTVAL PRIMARY KEY,
  cod_utilizador NUMBER(6)     NOT NULL REFERENCES utilizador,
  tipo_contacto  VARCHAR2(8)   NOT NULL CHECK (tipo_contacto IN ('TELEFONE','EMAIL')),
  valor          VARCHAR2(120) NOT NULL,
  CONSTRAINT uq_contacto UNIQUE (cod_utilizador, tipo_contacto, valor)
);

CREATE TABLE funcionario (
  cod_funcionario NUMBER(4)     DEFAULT seq_funcionario.NEXTVAL PRIMARY KEY,
  nome_completo   VARCHAR2(120) NOT NULL,
  cargo           VARCHAR2(60)  NOT NULL,
  telefone        VARCHAR2(20),
  email           VARCHAR2(120),
  data_admissao   DATE          NOT NULL,
  estado          VARCHAR2(10)  DEFAULT 'ACTIVO' NOT NULL CHECK (estado IN ('ACTIVO','INACTIVO'))
);


CREATE TABLE conta_acesso (
  cod_conta          NUMBER(8)    DEFAULT seq_conta_acesso.NEXTVAL PRIMARY KEY,
  nome_conta         VARCHAR2(40) NOT NULL UNIQUE,
  palavra_passe_hash VARCHAR2(128) NOT NULL,           -- nunca em texto simples
  cod_perfil         NUMBER(2)    NOT NULL REFERENCES perfil_acesso,
  cod_utilizador     NUMBER(6)    UNIQUE REFERENCES utilizador,
  cod_funcionario    NUMBER(4)    UNIQUE REFERENCES funcionario,
  CONSTRAINT ck_conta_titular CHECK (
    (cod_utilizador IS NOT NULL AND cod_funcionario IS NULL) OR
    (cod_utilizador IS NULL AND cod_funcionario IS NOT NULL))
);

CREATE TABLE viatura (
  matricula       VARCHAR2(15) PRIMARY KEY,
  marca           VARCHAR2(40) NOT NULL,
  modelo          VARCHAR2(40) NOT NULL,
  cor             VARCHAR2(30) NOT NULL,
  cod_tipo_veiculo NUMBER(2)   NOT NULL REFERENCES tipo_veiculo,
  estado          VARCHAR2(10) DEFAULT 'ACTIVA' NOT NULL CHECK (estado IN ('ACTIVA','INACTIVA')),
  data_registo    DATE         DEFAULT SYSDATE NOT NULL
);


CREATE TABLE utilizador_viatura (
  cod_utilizador_viatura NUMBER(8)  DEFAULT seq_utilizador_viatura.NEXTVAL PRIMARY KEY,
  cod_utilizador         NUMBER(6)  NOT NULL REFERENCES utilizador,
  matricula              VARCHAR2(15) NOT NULL REFERENCES viatura,
  tipo_vinculo           VARCHAR2(12) NOT NULL CHECK (tipo_vinculo IN ('PROPRIETARIO','ASSOCIADO')),
  autorizada             CHAR(1)    DEFAULT 'S' NOT NULL CHECK (autorizada IN ('S','N')),
  data_inicio            DATE       NOT NULL,
  data_fim               DATE,
  CONSTRAINT uq_utilizador_viatura UNIQUE (cod_utilizador, matricula, data_inicio),
  CONSTRAINT ck_vinculo_datas CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);


CREATE TABLE estacionamento (
  cod_estacionamento NUMBER(2)    DEFAULT seq_estacionamento.NEXTVAL PRIMARY KEY,
  nome               VARCHAR2(80) NOT NULL UNIQUE,
  localizacao        VARCHAR2(150),
  capacidade_maxima  NUMBER(4)    NOT NULL CHECK (capacidade_maxima BETWEEN 1 AND 500)
);

CREATE TABLE piso_area (
  cod_piso_area      NUMBER(3)    DEFAULT seq_piso_area.NEXTVAL PRIMARY KEY,
  cod_estacionamento NUMBER(2)    NOT NULL REFERENCES estacionamento,
  designacao         VARCHAR2(50) NOT NULL,
  tipo               VARCHAR2(5)  NOT NULL CHECK (tipo IN ('PISO','AREA')),
  CONSTRAINT uq_piso_area UNIQUE (cod_estacionamento, designacao)
);

CREATE TABLE  zona (
  cod_zona      NUMBER(3)    DEFAULT seq_zona.NEXTVAL PRIMARY KEY,
  cod_piso_area NUMBER(3)    NOT NULL REFERENCES piso_area,
  codigo_zona   VARCHAR2(10) NOT NULL UNIQUE,
  designacao    VARCHAR2(60)
);

CREATE TABLE vaga (
  cod_vaga           NUMBER(4)    DEFAULT seq_vaga.NEXTVAL PRIMARY KEY,
  cod_zona           NUMBER(3)    NOT NULL REFERENCES zona,
  codigo_vaga        VARCHAR2(15) NOT NULL UNIQUE,
  estado             VARCHAR2(15) DEFAULT 'LIVRE' NOT NULL
                     CHECK (estado IN ('LIVRE','OCUPADA','RESERVADA','BLOQUEADA','MANUTENCAO')),
  cod_categoria_vaga NUMBER(3)    NOT NULL REFERENCES categoria_vaga,
  observacoes        VARCHAR2(200)
);

CREATE TABLE permissao_categoria_vaga (
  cod_categoria_vaga       NUMBER(3) REFERENCES categoria_vaga,
  cod_categoria_utilizador NUMBER(3) REFERENCES categoria_utilizador,
  PRIMARY KEY (cod_categoria_vaga, cod_categoria_utilizador)
);

CREATE TABLE ponto_acesso (
  cod_ponto_acesso   NUMBER(3)    DEFAULT seq_ponto_acesso.NEXTVAL PRIMARY KEY,
  cod_estacionamento NUMBER(2)    NOT NULL REFERENCES estacionamento,
  designacao         VARCHAR2(50) NOT NULL,
  tipo               VARCHAR2(7)  NOT NULL CHECK (tipo IN ('ENTRADA','SAIDA','MISTO')),
  estado             VARCHAR2(10) DEFAULT 'ACTIVO' NOT NULL CHECK (estado IN ('ACTIVO','INACTIVO'))
);


CREATE TABLE tarifa (
  cod_tarifa               NUMBER(4)    DEFAULT seq_tarifa.NEXTVAL PRIMARY KEY,
  designacao               VARCHAR2(80) NOT NULL,
  cod_categoria_utilizador NUMBER(3)    NOT NULL REFERENCES categoria_utilizador,
  valor_hora               NUMBER(8,2)  NOT NULL CHECK (valor_hora >= 0),
  valor_maximo_diario      NUMBER(8,2)  CHECK (valor_maximo_diario >= 0),
  tolerancia_minutos       NUMBER(3)    NOT NULL CHECK (tolerancia_minutos >= 0),
  fraccao_minutos          NUMBER(3)    NOT NULL CHECK (fraccao_minutos > 0),
  data_inicio_vigencia     DATE         NOT NULL,
  data_fim_vigencia        DATE,
  CONSTRAINT ck_tarifa_vigencia CHECK (data_fim_vigencia IS NULL OR data_fim_vigencia >= data_inicio_vigencia)
);

CREATE TABLE reserva (
  cod_reserva                NUMBER(8)    DEFAULT seq_reserva.NEXTVAL PRIMARY KEY,
  cod_utilizador_viatura     NUMBER(8)    NOT NULL REFERENCES utilizador_viatura,
  cod_vaga                   NUMBER(4)    REFERENCES vaga,
  cod_categoria_vaga         NUMBER(3)    REFERENCES categoria_vaga,   -- categoria pretendida
  data_hora_pedido           TIMESTAMP(0) DEFAULT SYSTIMESTAMP NOT NULL,
  data_hora_inicio           TIMESTAMP(0) NOT NULL,
  data_hora_fim              TIMESTAMP(0) NOT NULL,
  estado                     VARCHAR2(15) DEFAULT 'SOLICITADA' NOT NULL
                             CHECK (estado IN ('SOLICITADA','CONFIRMADA','UTILIZADA','CANCELADA','EXPIRADA','NAO_COMPARECIDA')),
  motivo_cancelamento        VARCHAR2(200),
  CONSTRAINT ck_reserva_periodo CHECK (data_hora_fim > data_hora_inicio),
  CONSTRAINT ck_reserva_alvo    CHECK (cod_vaga IS NOT NULL OR cod_categoria_vaga IS NOT NULL)
);

CREATE TABLE ocorrencia (
  cod_ocorrencia        NUMBER(9)     DEFAULT seq_ocorrencia.NEXTVAL PRIMARY KEY,
  cod_tipo_ocorrencia   NUMBER(3)     NOT NULL REFERENCES tipo_ocorrencia,
  cod_funcionario       NUMBER(4)     NOT NULL REFERENCES funcionario,   -- quem regista (RN32)
  matricula             VARCHAR2(15)  REFERENCES viatura,
  cod_vaga              NUMBER(4)     REFERENCES vaga,
  cod_utilizador        NUMBER(6)     REFERENCES utilizador,
  data_hora_ocorrencia  TIMESTAMP(0)  NOT NULL,
  descricao             VARCHAR2(500) NOT NULL,
  estado                VARCHAR2(10)  DEFAULT 'ABERTA' NOT NULL CHECK (estado IN ('ABERTA','ENCERRADA','ANULADA')),
  justificacao_anulacao VARCHAR2(300),
  CONSTRAINT ck_ocorrencia_anulacao CHECK (estado <> 'ANULADA' OR justificacao_anulacao IS NOT NULL)
);

CREATE TABLE medida_ocorrencia (
  cod_medida      NUMBER(9)     DEFAULT seq_medida_ocorrencia.NEXTVAL PRIMARY KEY,
  cod_ocorrencia  NUMBER(9)     NOT NULL REFERENCES ocorrencia,
  cod_funcionario NUMBER(4)     NOT NULL REFERENCES funcionario,
  descricao       VARCHAR2(300) NOT NULL,
  data_hora       TIMESTAMP(0)  DEFAULT SYSTIMESTAMP NOT NULL
);

CREATE TABLE utilizacao (
  cod_utilizacao         NUMBER(9)     DEFAULT seq_utilizacao.NEXTVAL PRIMARY KEY,
  cod_utilizador_viatura NUMBER(8)     NOT NULL REFERENCES utilizador_viatura,
  cod_vaga               NUMBER(4)     NOT NULL REFERENCES vaga,
  cod_reserva            NUMBER(8)     UNIQUE REFERENCES reserva,          -- R: 1:1 opcional
  cod_tarifa             NUMBER(4)     REFERENCES tarifa,
  cod_ocorrencia_encerr  NUMBER(9)     REFERENCES ocorrencia,              -- encerramento administrativo
  tipo_acesso            VARCHAR2(10)  NOT NULL CHECK (tipo_acesso IN ('NORMAL','VISITANTE')),
  estado                 VARCHAR2(20)  DEFAULT 'ACTIVA' NOT NULL
                         CHECK (estado IN ('ACTIVA','ENCERRADA','ENCERRADA_ADMIN')),
  minutos_cobrados       NUMBER(6),
  valor_calculado        NUMBER(10,2)  CHECK (valor_calculado >= 0),
  valor_devido           NUMBER(10,2)  CHECK (valor_devido >= 0),
  isencao_autorizada     CHAR(1)       DEFAULT 'N' NOT NULL CHECK (isencao_autorizada IN ('S','N')),
  justificacao_isencao   VARCHAR2(200),
  CONSTRAINT ck_isencao CHECK (isencao_autorizada = 'N' OR justificacao_isencao IS NOT NULL)
);


CREATE TABLE entrada (
  cod_utilizacao     NUMBER(9)    PRIMARY KEY REFERENCES utilizacao,
  data_hora_entrada  TIMESTAMP(0) NOT NULL,
  cod_ponto_acesso   NUMBER(3)    NOT NULL REFERENCES ponto_acesso,
  cod_funcionario    NUMBER(4)    REFERENCES funcionario     -- NULL = mecanismo automático
);

CREATE TABLE saida (
  cod_utilizacao    NUMBER(9)    PRIMARY KEY REFERENCES utilizacao,
  data_hora_saida   TIMESTAMP(0) NOT NULL,
  cod_ponto_acesso  NUMBER(3)    NOT NULL REFERENCES ponto_acesso,
  cod_funcionario   NUMBER(4)    REFERENCES funcionario
);


CREATE TABLE ajuste_cobranca (
  cod_ajuste        NUMBER(9)     DEFAULT seq_ajuste_cobranca.NEXTVAL PRIMARY KEY,
  cod_utilizacao    NUMBER(9)     NOT NULL REFERENCES utilizacao,
  cod_funcionario   NUMBER(4)     NOT NULL REFERENCES funcionario,
  valor_anterior    NUMBER(10,2)  NOT NULL CHECK (valor_anterior >= 0),
  valor_novo        NUMBER(10,2)  NOT NULL CHECK (valor_novo >= 0),
  justificacao      VARCHAR2(200) NOT NULL,
  data_hora_ajuste  TIMESTAMP(0)  DEFAULT SYSTIMESTAMP NOT NULL
);

CREATE TABLE pagamento (
  cod_pagamento        NUMBER(9)    DEFAULT seq_pagamento.NEXTVAL PRIMARY KEY,
  cod_utilizacao       NUMBER(9)    NOT NULL REFERENCES utilizacao,
  cod_metodo_pagamento NUMBER(2)    NOT NULL REFERENCES metodo_pagamento,
  cod_funcionario      NUMBER(4)    REFERENCES funcionario,         -- quem recebe
  valor                NUMBER(10,2) NOT NULL CHECK (valor >= 0),    -- RN29
  data_hora_pagamento  TIMESTAMP(0) DEFAULT SYSTIMESTAMP NOT NULL,
  estado_transacao     VARCHAR2(12) DEFAULT 'PENDENTE' NOT NULL
                       CHECK (estado_transacao IN ('PENDENTE','CONCLUIDO','FALHADO','ESTORNADO')),
  referencia_transacao VARCHAR2(60)
);


CREATE TABLE notificacao (
  cod_notificacao   NUMBER(9)     DEFAULT seq_notificacao.NEXTVAL PRIMARY KEY,
  cod_utilizador    NUMBER(6)     NOT NULL REFERENCES utilizador,
  cod_reserva       NUMBER(8)     REFERENCES reserva,
  cod_utilizacao    NUMBER(9)     REFERENCES utilizacao,
  tipo_notificacao  VARCHAR2(25)  NOT NULL CHECK (tipo_notificacao IN
      ('RESERVA_CONFIRMADA','RESERVA_CANCELADA','RESERVA_ALTERADA','COBRANCA','PERMANENCIA_PROLONGADA')),
  canal             VARCHAR2(10)  NOT NULL CHECK (canal IN ('SMS','EMAIL','APLICACAO')),
  mensagem          VARCHAR2(300) NOT NULL,
  data_hora_envio   TIMESTAMP(0)  NOT NULL,
  data_hora_leitura TIMESTAMP(0),
  estado_envio      VARCHAR2(10)  NOT NULL CHECK (estado_envio IN ('ENVIADA','FALHADA')),
  CONSTRAINT ck_notif_origem CHECK (cod_reserva IS NULL OR cod_utilizacao IS NULL)
);

CREATE TABLE auditoria (
  cod_auditoria       NUMBER(12)     DEFAULT seq_auditoria.NEXTVAL PRIMARY KEY,
  data_hora_operacao  TIMESTAMP(0)   DEFAULT SYSTIMESTAMP NOT NULL,
  operacao            VARCHAR2(10)   NOT NULL CHECK (operacao IN ('INSERCAO','ALTERACAO','ANULACAO')),
  tabela_afectada     VARCHAR2(30)   NOT NULL,
  id_registo_afectado NUMBER(12)     NOT NULL,
  valor_anterior      VARCHAR2(1000),
  valor_novo          VARCHAR2(1000),
  cod_utilizador      NUMBER(6)      REFERENCES utilizador,
  cod_funcionario     NUMBER(4)      REFERENCES funcionario,
  CONSTRAINT ck_auditoria_autor CHECK (cod_utilizador IS NULL OR cod_funcionario IS NULL)
);


CREATE INDEX ix_vaga_zona            ON vaga (cod_zona);
CREATE INDEX ix_vaga_estado          ON vaga (estado);
CREATE INDEX ix_reserva_vaga_periodo ON reserva (cod_vaga, data_hora_inicio, data_hora_fim);
CREATE INDEX ix_utilizacao_vaga      ON utilizacao (cod_vaga, estado);
CREATE INDEX ix_utilizacao_uv        ON utilizacao (cod_utilizador_viatura);
CREATE INDEX ix_pagamento_utilizacao ON pagamento (cod_utilizacao);
CREATE INDEX ix_ocorrencia_data      ON ocorrencia (data_hora_ocorrencia);
CREATE INDEX ix_notificacao_utiliz   ON notificacao (cod_utilizador);


CREATE OR REPLACE VIEW vw_utilizacao AS
SELECT u.cod_utilizacao, u.cod_vaga, u.estado, e.data_hora_entrada, s.data_hora_saida,
       CASE WHEN s.data_hora_saida IS NOT NULL
            THEN ROUND((CAST(s.data_hora_saida AS DATE) - CAST(e.data_hora_entrada AS DATE)) * 1440)
       END AS tempo_permanencia_min
FROM utilizacao u
JOIN entrada e ON e.cod_utilizacao = u.cod_utilizacao
LEFT JOIN saida s ON s.cod_utilizacao = u.cod_utilizacao;

CREATE OR REPLACE VIEW vw_estacionamento_vagas AS
SELECT est.cod_estacionamento, est.nome, est.capacidade_maxima, COUNT(v.cod_vaga) AS total_vagas
FROM estacionamento est
LEFT JOIN piso_area p ON p.cod_estacionamento = est.cod_estacionamento
LEFT JOIN zona z      ON z.cod_piso_area      = p.cod_piso_area
LEFT JOIN vaga v      ON v.cod_zona           = z.cod_zona
GROUP BY est.cod_estacionamento, est.nome, est.capacidade_maxima;


