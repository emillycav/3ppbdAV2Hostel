
CREATE DATABASE IF NOT EXISTS hostel DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE hostel;

DROP TABLE IF EXISTS Reserva_Vagas;
DROP TABLE IF EXISTS Reservas;
DROP TABLE IF EXISTS Vagas;
DROP TABLE IF EXISTS Quartos;
DROP TABLE IF EXISTS Clientes;

CREATE TABLE Clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    cpf VARCHAR(14) NOT NULL UNIQUE,
    telefone VARCHAR(20),
    cartao_credito VARCHAR(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Quartos (
    id_quarto INT AUTO_INCREMENT PRIMARY KEY,
    numero VARCHAR(10) NOT NULL UNIQUE,
    capacidade INT NOT NULL,
    tem_banheiro TINYINT(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Vagas (
    id_vaga INT AUTO_INCREMENT PRIMARY KEY,
    id_quarto INT NOT NULL,
    numero_vaga VARCHAR(10) NOT NULL,
    posicao_beliche VARCHAR(20),
    perto_porta TINYINT(1) DEFAULT 0,
    perto_janela TINYINT(1) DEFAULT 0,
    sol_manha TINYINT(1) DEFAULT 0,
    pega_sol TINYINT(1) DEFAULT 1,
    preco_diaria DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (id_quarto) REFERENCES Quartos(id_quarto) ON DELETE CASCADE,
    UNIQUE KEY uq_quarto_vaga (id_quarto, numero_vaga)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Reservas (
    id_reserva INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    data_reserva TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'confirmada',
    valor_total DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Reserva_Vagas (
    id_reserva INT NOT NULL,
    id_vaga INT NOT NULL,
    PRIMARY KEY (id_reserva, id_vaga),
    FOREIGN KEY (id_reserva) REFERENCES Reservas(id_reserva) ON DELETE CASCADE,
    FOREIGN KEY (id_vaga) REFERENCES Vagas(id_vaga)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


INSERT INTO Quartos (numero, capacidade, tem_banheiro) VALUES ('101', 4, 1), ('102', 8, 0);

INSERT INTO Vagas (id_quarto, numero_vaga, posicao_beliche, perto_porta, perto_janela, sol_manha, pega_sol, preco_diaria) VALUES 
(1, 'Cama-01', 'baixo', 0, 1, 1, 1, 60.00),
(1, 'Cama-02', 'cima', 1, 0, 0, 1, 50.00),
(2, 'Cama-03', 'nao_beliche', 0, 1, 1, 0, 45.00);