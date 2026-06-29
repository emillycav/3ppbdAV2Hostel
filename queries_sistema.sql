-- =============================================================================
-- SCRIPT DE OPERAÇÕES DO SISTEMA (CRUD E QUERIES AVANÇADAS)
-- Banco de Dados: hostel
-- =============================================================================

USE hostel;


INSERT INTO Clientes (nome, email, cpf, telefone, cartao_credito) 
VALUES ('Emilly Silva', 'emilly@email.com', '111.222.333-44', '(11) 99999-8888', '1234-5678-9012-3456');

SELECT * FROM Clientes;
SELECT * FROM Clientes WHERE id_cliente = 1;
SELECT nome, email FROM Clientes WHERE nome LIKE '%Silva%';

UPDATE Clientes 
SET telefone = '(11) 98888-7777', cartao_credito = '4321-8765-1111-2222' 
WHERE id_cliente = 1;

DELETE FROM Clientes WHERE id_cliente = 3;


INSERT INTO Quartos (numero, capacidade, tem_banheiro) VALUES ('201', 4, 1);

SELECT * FROM Quartos;
SELECT * FROM Quartos WHERE capacidade = 8;

UPDATE Quartos SET numero = '201-A' WHERE id_quarto = 4;

DELETE FROM Quartos WHERE id_quarto = 4;


INSERT INTO Vagas (id_quarto, numero_vaga, posicao_beliche, perto_porta, perto_janela, sol_manha, pega_sol, preco_diaria) 
VALUES (1, 'Cama-05', 'baixo', 0, 1, 1, 1, 65.00);

SELECT * FROM Vagas WHERE posicao_beliche = 'baixo';
SELECT * FROM Vagas WHERE preco_diaria <= 50.00;

UPDATE Vagas SET preco_diaria = 55.00 WHERE id_vaga = 2;

DELETE FROM Vagas WHERE id_vaga = 4;


INSERT INTO Reservas (id_cliente, data_inicio, data_fim, valor_total) 
VALUES (1, '2026-07-20', '2026-07-25', 250.00);

SELECT * FROM Reservas WHERE status = 'confirmada';

UPDATE Reservas SET status = 'cancelada' WHERE id_reserva = 1;

DELETE FROM Reservas WHERE id_reserva = 2;


INSERT INTO Reserva_Vagas (id_reserva, id_vaga) VALUES (2, 3);

SELECT * FROM Reserva_Vagas;


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
AND q.tem_banheiro = 1          
AND v.posicao_beliche = 'baixo';   


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



SELECT 
    q.numero AS numero_quarto,
    q.capacidade AS capacidade_total_vagas,
    COUNT(v.id_vaga) AS vagas_configuradas,
    SUM(v.preco_diaria) AS potencial_faturamento_diario
FROM Quartos q
LEFT JOIN Vagas v ON q.id_quarto = v.id_quarto
GROUP BY q.id_quarto, q.numero, q.capacidade;
