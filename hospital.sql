DROP DATABASE IF EXISTS hospital_db;
CREATE DATABASE hospital_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE hospital_db;

CREATE TABLE pacientes (
    id_paciente INT AUTO_INCREMENT PRIMARY KEY,
    nome_paciente VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) NOT NULL,
    data_nascimento DATE NOT NULL,
    telefone_paciente VARCHAR(20),
    convenio VARCHAR(50) NOT NULL DEFAULT 'Particular',
    CONSTRAINT uk_pacientes_cpf UNIQUE (cpf)
) ENGINE=InnoDB;

CREATE TABLE medicos (
    id_medico INT AUTO_INCREMENT PRIMARY KEY,
    nome_medico VARCHAR(100) NOT NULL,
    crm VARCHAR(20) NOT NULL,
    especialidade VARCHAR(60) NOT NULL,
    CONSTRAINT uk_medicos_crm UNIQUE (crm)
) ENGINE=InnoDB;

CREATE TABLE quartos (
    id_quarto INT AUTO_INCREMENT PRIMARY KEY,
    numero_quarto INT NOT NULL,
    andar INT NOT NULL,
    tipo_quarto VARCHAR(40) NOT NULL,
    status_quarto ENUM('Livre', 'Ocupado', 'Manutenção') NOT NULL DEFAULT 'Livre',
    CONSTRAINT uk_quartos_numero UNIQUE (numero_quarto)
) ENGINE=InnoDB;

CREATE TABLE internacoes (
    id_internacao INT AUTO_INCREMENT PRIMARY KEY,
    id_paciente INT NOT NULL,
    id_quarto INT NOT NULL,
    data_entrada DATE NOT NULL,
    data_saida DATE NULL,
    valor_diaria DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_internacoes_paciente FOREIGN KEY (id_paciente)
        REFERENCES pacientes(id_paciente) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_internacoes_quarto FOREIGN KEY (id_quarto)
        REFERENCES quartos(id_quarto) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uk_internacoes_quarto_entrada UNIQUE (id_quarto, data_entrada),
    CONSTRAINT chk_internacoes_datas CHECK (data_saida IS NULL OR data_saida >= data_entrada),
    CONSTRAINT chk_internacoes_diaria CHECK (valor_diaria > 0)
) ENGINE=InnoDB;

CREATE TABLE consultas (
    id_consulta INT AUTO_INCREMENT PRIMARY KEY,
    id_paciente INT NOT NULL,
    id_medico INT NOT NULL,
    data_consulta DATETIME NOT NULL,
    status_consulta ENUM('Agendada', 'Realizada', 'Cancelada') NOT NULL DEFAULT 'Agendada',
    valor_consulta DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_consultas_paciente FOREIGN KEY (id_paciente)
        REFERENCES pacientes(id_paciente) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_consultas_medico FOREIGN KEY (id_medico)
        REFERENCES medicos(id_medico) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uk_consultas_medico_horario UNIQUE (id_medico, data_consulta),
    CONSTRAINT chk_consultas_valor CHECK (valor_consulta >= 0)
) ENGINE=InnoDB;

CREATE TABLE prescricoes (
    id_prescricao INT AUTO_INCREMENT PRIMARY KEY,
    id_consulta INT NOT NULL,
    medicamento VARCHAR(100) NOT NULL,
    dosagem VARCHAR(100) NOT NULL,
    quantidade INT NOT NULL,
    CONSTRAINT fk_prescricoes_consulta FOREIGN KEY (id_consulta)
        REFERENCES consultas(id_consulta) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_prescricoes_qtd CHECK (quantidade > 0)
) ENGINE=InnoDB;

DELIMITER //

CREATE TRIGGER trg_bloqueia_sobreposicao_leito
BEFORE INSERT ON internacoes
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM internacoes
        WHERE id_quarto = NEW.id_quarto
          AND NEW.data_entrada <= COALESCE(data_saida, '9999-12-31')
          AND COALESCE(NEW.data_saida, '9999-12-31') >= data_entrada
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Conflito de alocação: o quarto já possui internação no período informado.';
    END IF;
END //

DELIMITER ;

INSERT INTO pacientes (nome_paciente, cpf, data_nascimento, telefone_paciente, convenio) VALUES
('Ana Silva', '111.222.333-01', '1985-03-15', '(11) 98765-4321', 'Unimed'),
('Carlos Oliveira', '222.333.444-02', '1990-07-22', '(11) 97654-3210', 'Bradesco Saúde'),
('Maria Santos', '333.444.555-03', '1978-11-05', '(11) 96543-2109', 'Unimed'),
('João Pedro Silva', '444.555.666-04', '2000-01-30', '(11) 95432-1098', 'Particular'),
('Fernanda Costa', '555.666.777-05', '1995-09-12', '(11) 94321-0987', 'Amil'),
('Roberto Almeida', '666.777.888-06', '1962-04-18', '(11) 93210-9876', 'SulAmérica'),
('Juliana Oliveira', '777.888.999-07', '1988-12-08', '(11) 92109-8765', 'Unimed Pleno'),
('Lucas Souza', '888.999.000-08', '2003-05-25', '(11) 91098-7654', 'Particular'),
('Beatriz Lima', '999.000.111-09', '1973-08-02', '(11) 90987-6543', 'Bradesco Saúde'),
('Ricardo Pereira', '000.111.222-10', '1981-10-19', '(11) 98877-6655', 'Amil');

INSERT INTO medicos (nome_medico, crm, especialidade) VALUES
('Dr. Marcos Andrade', 'CRM/SP 12345', 'Cardiologia'),
('Dra. Patricia Lima', 'CRM/SP 23456', 'Pediatria'),
('Dr. Roberto Silva', 'CRM/SP 34567', 'Cardiologia Pediatrica'),
('Dra. Camila Rocha', 'CRM/SP 45678', 'Cirurgia Geral'),
('Dr. Gustavo Santos', 'CRM/SP 56789', 'Ortopedia'),
('Dra. Vanessa Martins', 'CRM/SP 67890', 'Cirurgia Vascular'),
('Dr. Felipe Barbosa', 'CRM/SP 78901', 'Neurologia'),
('Dra. Renata Mello', 'CRM/SP 89012', 'Ginecologia'),
('Dr. Eduardo Ramos', 'CRM/SP 90123', 'Dermatologia'),
('Dra. Claudia Castro', 'CRM/SP 01234', 'Cirurgia Plastica');

INSERT INTO quartos (numero_quarto, andar, tipo_quarto, status_quarto) VALUES
(101, 1, 'UTI', 'Ocupado'),
(102, 1, 'Enfermaria', 'Livre'),
(201, 2, 'Apartamento', 'Ocupado'),
(202, 2, 'Apartamento', 'Livre'),
(301, 3, 'UTI', 'Ocupado'),
(302, 3, 'Enfermaria', 'Ocupado'),
(401, 4, 'Suíte VIP', 'Livre'),
(402, 4, 'Apartamento', 'Ocupado'),
(501, 5, 'UTI', 'Livre'),
(502, 5, 'Enfermaria', 'Ocupado');

INSERT INTO internacoes (id_paciente, id_quarto, data_entrada, data_saida, valor_diaria) VALUES
(1, 1, '2026-02-10', '2026-02-20', 450.00),
(2, 3, '2026-03-01', '2026-03-10', 300.00),
(3, 5, '2026-04-15', '2026-04-25', 500.00),
(7, 6, '2026-05-01', '2026-05-08', 250.00),
(5, 8, '2026-06-10', '2026-06-18', 350.00),
(6, 10, '2026-07-01', '2026-07-10', 280.00),
(2, 1, '2026-08-05', '2026-08-12', 450.00),
(4, 2, '2026-01-15', '2026-01-22', 200.00),
(8, 4, '2026-02-20', '2026-02-28', 320.00),
(9, 7, '2026-03-12', '2026-03-19', 600.00);

INSERT INTO consultas (id_paciente, id_medico, data_consulta, status_consulta, valor_consulta) VALUES
(1, 1, '2026-01-10 09:00:00', 'Realizada', 350.00),
(1, 4, '2026-02-05 14:00:00', 'Realizada', 500.00),
(2, 3, '2026-03-01 10:30:00', 'Realizada', 400.00),
(3, 2, '2026-03-15 11:00:00', 'Realizada', 280.00),
(4, 6, '2026-04-10 15:00:00', 'Realizada', 550.00),
(5, 5, '2026-05-02 08:30:00', 'Realizada', 320.00),
(6, 1, '2026-05-20 16:00:00', 'Realizada', 350.00),
(7, 10, '2026-06-01 13:00:00', 'Realizada', 600.00),
(8, 8, '2026-06-15 10:00:00', 'Realizada', 300.00),
(1, 4, '2026-07-01 14:00:00', 'Realizada', 500.00);

INSERT INTO prescricoes (id_consulta, medicamento, dosagem, quantidade) VALUES
(1, 'Dipirona 500mg', '1 comprimido de 6h/6h', 20),
(1, 'Amoxicilina 500mg', '1 capsula de 8h/8h', 21),
(2, 'Ibuprofeno 600mg', '1 comprimido de 12h/12h', 10),
(3, 'Paracetamol 750mg', '1 comprimido de 8h/8h', 15),
(4, 'Omeprazol 20mg', '1 capsula em jejum', 30),
(5, 'Cetanest', 'Aplicar via IV', 5),
(6, 'Dorflex', '1 comprimido se dor', 12),
(7, 'Atenolol 50mg', '1 comprimido ao dia', 30),
(8, 'Cefalexina 500mg', '1 capsula de 6h/6h', 28),
(10, 'Tramadol 50mg', '1 comprimido de 8h/8h', 10);