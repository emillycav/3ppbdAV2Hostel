import mysql.connector
from mysql.connector import Error
from datetime import datetime

# Configuração da conexão com o phpMyAdmin / MySQL
def obter_conexao():
    try:
        conexao = mysql.connector.connect(
            host='localhost',
            user='root',         # Usuário padrão do phpMyAdmin
            password='',         # Senha padrão do phpMyAdmin (geralmente vazia)
            database='hostel'    # Seu banco de dados
        )
        return conexao
    except Error as e:
        print(f"❌ Erro ao conectar ao MySQL: {e}")
        return None

# ==========================================
# 1. OPERAÇÕES CRUD: CLIENTES
# ==========================================

def cadastrar_cliente(nome, email, cpf, telefone, cartao_credito):
    conn = obter_conexao()
    if not conn: return
    cursor = conn.cursor()
    
    query = """INSERT INTO Clientes (nome, email, cpf, telefone, cartao_credito) 
               VALUES (%s, %s, %s, %s, %s)"""
    valores = (nome, email, cpf, telefone, cartao_credito)
    
    try:
        cursor.execute(query, valores)
        conn.commit()
        print(f"✅ Cliente '{nome}' cadastrado com sucesso!")
    except Error as e:
        print(f"❌ Erro ao cadastrar cliente: {e}")
    finally:
        cursor.close()
        conn.close()

def listar_clientes():
    conn = obter_conexao()
    if not conn: return
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT id_cliente, nome, email, cpf FROM Clientes")
    clientes = cursor.fetchall()
    
    print("\n--- LISTA DE CLIENTES ---")
    for c in clientes:
        print(f"ID: {c['id_cliente']} | Nome: {c['nome']} | E-mail: {c['email']} | CPF: {c['cpf']}")
    
    cursor.close()
    conn.close()

def atualizar_cliente(id_cliente, novo_telefone, novo_cartao):
    conn = obter_conexao()
    if not conn: return
    cursor = conn.cursor()
    
    query = "UPDATE Clientes SET telefone = %s, cartao_credito = %s WHERE id_cliente = %s"
    
    try:
        cursor.execute(query, (novo_telefone, novo_cartao, id_cliente))
        conn.commit()
        print(f"✅ Cadastro do cliente ID {id_cliente} atualizado!")
    except Error as e:
        print(f"❌ Erro ao atualizar: {e}")
    finally:
        cursor.close()
        conn.close()

def deletar_cliente(id_cliente):
    conn = obter_conexao()
    if not conn: return
    cursor = conn.cursor()
    
    try:
        cursor.execute("DELETE FROM Clientes WHERE id_cliente = %s", (id_cliente,))
        conn.commit()
        print(f"✅ Cliente ID {id_cliente} removido do sistema.")
    except Error as e:
        print(f"❌ Erro ao deletar (Pode haver reservas vinculadas): {e}")
    finally:
        cursor.close()
        conn.close()


# ==========================================
# 2. FUNCIONALIDADE PRINCIPAL: BUSCA DINÂMICA
# ==========================================

def buscar_vagas_disponiveis(data_ini, data_fim, apenas_com_banheiro=None, apenas_sol_manha=None, beliche_pref=None):
    conn = obter_conexao()
    if not conn: return []
    cursor = conn.cursor(dictionary=True)
    
    # Query base que checa colisão de datas ignorando vagas ocupadas no período
    query = """
        SELECT v.id_vaga, q.numero AS quarto, q.tem_banheiro, v.numero_vaga, v.posicao_beliche, v.preco_diaria
        FROM Vagas v
        JOIN Quartos q ON v.id_quarto = q.id_quarto
        WHERE v.id_vaga NOT IN (
            SELECT rv.id_vaga FROM Reserva_Vagas rv
            JOIN Reservas r ON rv.id_reserva = r.id_reserva
            WHERE r.status = 'confirmada'
              AND NOT (r.data_fim <= %s OR r.data_inicio >= %s)
        )
    """
    parametros = [data_ini, data_fim]
    
    # Filtros dinâmicos opcionais solicitados no minimundo
    if apenas_com_banheiro is not None:
        query += " AND q.tem_banheiro = %s"
        parametros.append(1 if apenas_com_banheiro else 0)
    if apenas_sol_manha is not None:
        query += " AND v.sol_manha = %s"
        parametros.append(1 if apenas_sol_manha else 0)
    if beliche_pref:
        query += " AND v.posicao_beliche = %s"
        parametros.append(beliche_pref)
        
    cursor.execute(query, tuple(parametros))
    vagas = cursor.fetchall()
    cursor.close()
    conn.close()
    return vagas


# ==========================================
# 3. REGRAS DE NEGÓCIO: RESERVA E CANCELAMENTO
# ==========================================

def efetuar_reserva(id_cliente, lista_id_vagas, data_ini, data_fim):
    conn = obter_conexao()
    if not conn: return
    cursor = conn.cursor()
    
    # Cálculo das diárias (Meio-dia ao meio-dia)
    d1 = datetime.strptime(data_ini, "%Y-%m-%d")
    d2 = datetime.strptime(data_fim, "%Y-%m-%d")
    dias = (d2 - d1).days
    
    if dias <= 0:
        print("❌ Erro: A data de término deve ser posterior à data de início.")
        return
        
    # Somando o valor total das diárias de todas as vagas escolhidas
    valor_total = 0.0
    for id_vaga in lista_id_vagas:
        cursor.execute("SELECT preco_diaria FROM Vagas WHERE id_vaga = %s", (id_vaga,))
        res = cursor.fetchone()
        if res:
            valor_total += float(res[0]) * dias

    try:
        # 1. Cria o registro da Reserva
        query_reserva = "INSERT INTO Reservas (id_cliente, data_inicio, data_fim, valor_total) VALUES (%s, %s, %s, %s)"
        cursor.execute(query_reserva, (id_cliente, data_ini, data_fim, valor_total))
        id_reserva = cursor.lastrowid
        
        # 2. Vincula as vagas à reserva criada (Tabela Associativa N:M)
        for id_vaga in lista_id_vagas:
            cursor.execute("INSERT INTO Reserva_Vagas (id_reserva, id_vaga) VALUES (%s, %s)", (id_reserva, id_vaga))
            
        conn.commit()
        print(f"🎉 Reserva #{id_reserva} criada com sucesso para {dias} diárias! Valor Total cobrado no cartão: R$ {valor_total:.2f}")
    except Error as e:
        print(f"❌ Erro ao processar reserva: {e}")
    finally:
        cursor.close()
        conn.close()

def cancelar_reserva(id_reserva):
    conn = obter_conexao()
    if not conn: return
    cursor = conn.cursor()
    
    cursor.execute("SELECT data_inicio FROM Reservas WHERE id_reserva = %s", (id_reserva,))
    res = cursor.fetchone()
    
    if not res:
        print("❌ Reserva não encontrada.")
        cursor.close()
        conn.close()
        return
        
    # Regra do minimundo: cancelamento aceito apenas até 3 dias antes do check-in
    data_inicio_reserva = datetime.combine(res[0], datetime.min.time())
    hoje = datetime.now()
    dias_antecedencia = (data_inicio_reserva - hoje).days
    
    if dias_antecedencia >= 3:
        cursor.execute("UPDATE Reservas SET status = 'cancelada' WHERE id_reserva = %s", (id_reserva,))
        conn.commit()
        print(f"✅ Reserva #{id_reserva} cancelada com sucesso. Estorno solicitado.")
    else:
        print("🚫 Cancelamento recusado: Fora do prazo limite (Menos de 3 dias de antecedência do início da estadia).")
        
    cursor.close()
    conn.close()


# ==========================================
# MENU INTERATIVO DE EXECUÇÃO VIA TERMINAL
# ==========================================

def menu():
    print("\n" + "="*40)
    print("      SISTEMA ALBERGUE DO SR. ALMEIDA")
    print("="*40)
    print("1. Cadastrar Cliente")
    print("2. Listar Clientes")
    print("3. Atualizar Cliente")
    print("4. Deletar Cliente")
    print("5. Consultar Vagas Disponíveis (Filtros)")
    print("6. Efetuar uma Reserva")
    print("7. Cancelar uma Reserva")
    print("0. Sair")
    print("="*40)

if __name__ == "__main__":
    while True:
        menu()
        opcao = input("Escolha uma opção: ")
        
        if opcao == "1":
            nome = input("Nome do Cliente: ")
            email = input("E-mail: ")
            cpf = input("CPF: ")
            tel = input("Telefone: ")
            cartao = input("Cartão de Crédito: ")
            cadastrar_cliente(nome, email, cpf, tel, cartao)
            
        elif opcao == "2":
            listar_clientes()
            
        elif opcao == "3":
            id_c = int(input("ID do Cliente que deseja alterar: "))
            tel = input("Novo Telefone: ")
            cartao = input("Novo Cartão de Crédito: ")
            atualizar_cliente(id_c, tel, cartao)
            
        elif opcao == "4":
            id_c = int(input("ID do Cliente a ser removido: "))
            deletar_cliente(id_c)
            
        elif opcao == "5":
            d_ini = input("Data Inicial (AAAA-MM-DD): ")
            d_fim = input("Data Final (AAAA-MM-DD): ")
            banh = input("Deseja quarto com banheiro? (S/N): ").strip().upper() == 'S'
            sol = input("Deseja com sol da manhã? (S/N): ").strip().upper() == 'S'
            pref_b = input("Posição do Beliche (cima / baixo / nao_beliche): ").strip().lower()
            
            vagas = buscar_vagas_disponiveis(d_ini, d_fim, apenas_com_banheiro=banh, apenas_sol_manha=sol, beliche_pref=pref_b)
            
            print(f"\n--- VAGAS DISPONÍVEIS DE {d_ini} A {d_fim} ---")
            for v in vagas:
                status_b = "Sim" if v['tem_banheiro'] else "Não"
                print(f"ID Vaga: {v['id_vaga']} | Quarto {v['quarto']} (Com Banheiro: {status_b}) | Vaga: {v['numero_vaga']} | Cama: {v['posicao_beliche']} | Diária: R$ {v['preco_diaria']}")
                
        elif opcao == "6":
            id_c = int(input("ID do Cliente que está reservando: "))
            d_ini = input("Data Inicial (AAAA-MM-DD): ")
            d_fim = input("Data Final (AAAA-MM-DD): ")
            vagas_str = input("IDs das vagas que deseja reservar (separados por vírgula. Ex: 1,2): ")
            lista_vagas = [int(i.strip()) for i in vagas_str.split(",")]
            
            efetuar_reserva(id_c, lista_vagas, d_ini, d_fim)
            
        elif opcao == "7":
            id_r = int(input("Digite o ID da reserva que deseja cancelar: "))
            cancelar_reserva(id_r)
            
        elif opcao == "0":
            print("Saindo do sistema... Até logo, Sr. Almeida!")
            break
        else:
            print("Opção inválida! Tente novamente.")