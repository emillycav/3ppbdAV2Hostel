-- =============================================================================
-- SCRIPT DE OPERAÇÕES DO SISTEMA (CRUD E QUERIES AVANÇADAS)
-- Banco de Dados: hostel
-- =============================================================================

USE hostel;


-- Inclusão (Create)
INSERT INTO Clientes (nome, email, cpf, telefone, cartao_credito) 
VALUES ('Emilly Silva', 'emilly@email.com', '111.222.333-44', '(11) 99999-8888', '1234-5678-9012-3456');

-- Seleção Geral e Filtrada (Read)
SELECT * FROM Clientes;
SELECT * FROM Clientes WHERE id_cliente = 1;
SELECT nome, email FROM Clientes WHERE nome LIKE '%Silva%';

-- Alteração (Update)
UPDATE Clientes 
SET telefone = '(11) 98888-7777', cartao_credito = '4321-8765-1111-2222' 
WHERE id_cliente = 1;

-- Exclusão (Delete)
DELETE FROM Clientes WHERE id_cliente = 3;


-- -----------------------------------------------------------------------------
-- TABELA: Quartos
-- -----------------------------------------------------------------------------

-- Inclusão (Create)
INSERT INTO Quartos (numero, capacidade, tem_banheiro) VALUES ('201', 4, 1);

-- Seleção (Read)
SELECT * FROM Quartos;
SELECT * FROM Quartos WHERE capacidade = 8;

-- Alteração (Update)
UPDATE Quartos SET numero = '201-A' WHERE id_quarto = 4;

-- Exclusão (Delete)
DELETE FROM Quartos WHERE id_quarto = 4;


-- -----------------------------------------------------------------------------
-- TABELA: Vagas (Camas)
-- -----------------------------------------------------------------------------

-- Inclusão (Create)
INSERT INTO Vagas (id_quarto, numero_vaga, posicao_beliche, perto_porta, perto_janela, sol_manha, pega_sol, preco_diaria) 
VALUES (1, 'Cama-05', 'baixo', 0, 1, 1, 1, 65.00);

-- Seleção (Read)
SELECT * FROM Vagas WHERE posicao_beliche = 'baixo';
SELECT * FROM Vagas WHERE preco_diaria <= 50.00;

-- Alteração (Update)
UPDATE Vagas SET preco_diaria = 55.00 WHERE id_vaga = 2;

-- Exclusão (Delete)
DELETE FROM Vagas WHERE id_vaga = 4;


-- -----------------------------------------------------------------------------
-- TABELA: Reservas
-- -----------------------------------------------------------------------------

-- Inclusão (Create)
INSERT INTO Reservas (id_cliente, data_inicio, data_fim, valor_total) 
VALUES (1, '2026-07-20', '2026-07-25', 250.00);

-- Seleção (Read)
SELECT * FROM Reservas WHERE status = 'confirmada';

-- Alteração (Update - Exemplo: Cancelamento mantendo histórico)
UPDATE Reservas SET status = 'cancelada' WHERE id_reserva = 1;

-- Exclusão (Delete)
DELETE FROM Reservas WHERE id_reserva = 2;


-- -----------------------------------------------------------------------------
-- TABELA ASSOCIATIVA: Reserva_Vagas (Relacionamento N:M)
-- -----------------------------------------------------------------------------

-- Inclusão (Vincula a Reserva 2 à Vaga 3)
INSERT INTO Reserva_Vagas (id_reserva, id_vaga) VALUES (2, 3);

-- Seleção (Read)
SELECT * FROM Reserva_Vagas;


-- =============================================================================
-- 2. FUNCIONALIDADES PRINCIPAIS E RELATÓRIOS APROFUNDADOS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- FUNCIONALIDADE MÁSTER: Busca de Vagas Disponíveis sem colisão de datas
-- -----------------------------------------------------------------------------
-- O coração do sistema. Varre o banco buscando vagas que NÃO possuem reservas 
-- ativas no período que o cliente deseja viajar (Ex: de 12/07/2026 a 18/07/2026)
-- filtrando por preferências específicas (Ex: Quarto com banheiro e cama de baixo).

SELECT 
    v.id_vaga,
    q.numero AS numero_quarto,
    q.capacidade,
    q.tem_banheiro,
    v.numero_vaga,
    v.posicao_beliche,
    v.preco_diaria
FROM Vagas v
JOIN Quartos q ON v.id_quarto = q.id_quarto
WHERE v.id_vaga NOT IN (
    SELECT rv.id_vaga 
    FROM Reserva_Vagas rv
    JOIN Reservas r ON rv.id_reserva = r.id_reserva
    WHERE r.status = 'confirmada'
      AND NOT (r.data_fim <= '2026-07-12' OR r.data_inicio >= '2026-07-18')
)
AND q.tem_banheiro = 1              -- Filtro de preferência
AND v.posicao_beliche = 'baixo';    -- Filtro de preferência


-- -----------------------------------------------------------------------------
-- VISÃO DE OCUPAÇÃO: Relatório Geral de Reservas dos Clientes
-- -----------------------------------------------------------------------------
-- Junta as pontas do banco para mostrar de forma limpa quem reservou o quê,
-- em qual quarto, quando e quanto custou. Excelente para a tela do administrador.

SELECT 
    r.id_reserva,
    c.nome AS nome_cliente,
    q.numero AS numero_quarto,
    v.numero_vaga,
    DATE_FORMAT(r.data_inicio, '%d/%m/%Y') AS check_in,
    DATE_FORMAT(r.data_fim, '%d/%m/%Y') AS check_out,
    r.status,
    r.valor_total
FROM Reservas r
JOIN Clientes c ON r.id_cliente = c.id_cliente
JOIN Reserva_Vagas rv ON r.id_reserva = rv.id_reserva
JOIN Vagas v ON rv.id_vaga = v.id_vaga
JOIN Quartos q ON v.id_quarto = q.id_quarto
ORDER BY r.data_inicio ASC;


-- -----------------------------------------------------------------------------
-- RELATÓRIO GERENCIAL: Faturamento e Estatísticas por Quarto
-- -----------------------------------------------------------------------------
-- Query analítica que ajuda o Sr. Almeida a ver qual quarto traz mais dinheiro
-- e qual tem a maior quantidade de vagas cadastradas.

SELECT 
    q.numero AS numero_quarto,
    q.capacidade AS capacidade_total_vagas,
    COUNT(v.id_vaga) AS vagas_configuradas,
    SUM(v.preco_diaria) AS potencial_faturamento_diario
FROM Quartos q
LEFT JOIN Vagas v ON q.id_quarto = v.id_quarto
GROUP BY q.id_quarto, q.numero, q.capacidade;