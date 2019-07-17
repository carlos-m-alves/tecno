--
-- Carlos Henrique Michtal Alves
-- enriqq3d@gmail.com
-- Script de resolução do exercício.  
-- A partir do script backup-data.sql foram executadas as seguintes consultas.
-- Cada consulta possui comentarios acima explicando seu funcionamento.
--
-- CONSULTA que faz inserção dos dados na tabela 'teste.cliente'
--
-- Foi utilizada a tabela 'exam-backup.usuarios' para buscar nome, email e cpf para inserir na tabela 'teste.cliente'.
--
insert into teste.cliente (nome,email,cpf) (
	select nome,`e-mail`,cpf from usuarios
);

-- CONSULTA que faz inserção dos dados na tabela 'teste.cliente'
--
-- Foi utilizada a tabela 'teste.detalhadas' para buscar as informacoes nome, numero_vigencia, valor_padrao e tipo_vigencia.
-- Foram criados identificadores para o campo recorrencia da tabela 'teste.detalhadas' baseado no tipo do plano.
-- Anual			== 1
-- Gympass			== 2
-- GYMPASS Sessão	== 3
-- LIGHT - Anual	== 4
-- Mensal			== 5
-- Semestral		== 6
-- Trimestral		== 7
--
-- Também, baseado no campo recorrencia foi criado o campo numero_vigencia que representa o tempo de vigencia do contrato.
-- 'Anual' 			== 365
-- 'Gympass' 		== 1
-- 'GYMPASS Sessão' == 30
-- 'LIGHT - Anual' 	== 365
-- 'Mensal' 		== 30
-- 'Semestral' 		== 180
-- 'Trimestral' 	== 90
--
insert into teste.contrato (nome,numero_vigencia,valor_padrao,tipo_vigencia) (
	SELECT 
		recorrencia as nome
        ,CASE WHEN recorrencia = 'Anual' THEN 365
			WHEN recorrencia = 'Gympass' THEN 1
			WHEN recorrencia = 'GYMPASS Sessão' THEN 30
			WHEN recorrencia = 'LIGHT - Anual' THEN 365
			WHEN recorrencia = 'Mensal' THEN 30
			WHEN recorrencia = 'Semestral' THEN 180
			WHEN recorrencia = 'Trimestral' THEN 90
		END as numero_vigencia
		,valor as valor_padrao
		,CASE WHEN recorrencia = 'Anual' THEN 1
			WHEN recorrencia = 'Gympass' THEN 2
			WHEN recorrencia = 'GYMPASS Sessão' THEN 3
			WHEN recorrencia = 'LIGHT - Anual' THEN 4
			WHEN recorrencia = 'Mensal' THEN 5
			WHEN recorrencia = 'Semestral' THEN 6
			WHEN recorrencia = 'Trimestral' THEN 7
		END as tipo_vigencia
	FROM detalhadas
);

-- CONSULTA que faz inserção dos dados na tabela CLIENTE_VENDA
-- 
-- Foi utilizada a tabela 'exam-backup.relatorio_vendas' para buscar as informações necessarias para preencher os campos da tabela 'teste.cliente_venda'.
-- O campo 'data_da_venda' da tabela 'exam-backup.relatorio_vendas' foi convertido para DATE, uma vez que o campo da tabela 'teste.cliente_venda' é do tipo TIMESTAMP.
-- Foi feito um cruzamento com as informacoes da tabela 'teste.cliente' para buscar o identificador do cliente.
--
INSERT INTO teste.cliente_venda (cliente_id,valor,valor_desconto,valor_aberto,data_venda,codigo_importacao) (
	select t2.id as cliente_id,
		valor_total as valor, desconto as valor_desconto, valor_bruto as valor_aberto, STR_TO_DATE(data_da_venda,'%d/%m/%Y') as data_venda
        ,codigo_da_venda as codigo_importacao
	from relatorio_vendas t1
	inner join teste.cliente t2 on t1.cliente = t2.nome
);

-- CONSULTA que faz inserção dos dados na tabela LANCAMENTOS
--
-- Foram criados identificadores para que seja possível inserir os registros no campo 'tipo_recebimento' da tabela 'lancamentos'.
-- Cartão de Crédito			== 1
-- Cartão de Crédito Online		== 2
-- Cartão de Débito				== 3
-- Cheque						== 4
-- Dinheiro						== 5
-- Transferência				== 6
-- Transferência / Depósito		== 7
--
-- A consulta não funciona. O motivo acusado é data incorreta na coluna 'data_lancamento' mesmo convertendo para o tipo 'date'.
-- A coluna 'forma_pagto' da tabela 'contas_a_receber' é tratada e gerado identificadores utilizando CASE WHEN.
-- Os campos de data foram tratados usando a funcao de conversao STR_TO_DATE.
-- A coluna 'descricao' da tabela 'contas_a_receber' foi dividida para obter o identificador da venda.
-- A tabela 't2' gerada pela sub consulta contem a última data que foi realizado o pagamento da parcela venda em questão. Trazendo o identificador da venda também.
-- A tabela 't3' gerada pela sub consulta contem a quantidade de parcelas que já foram pagas e estão registradas na tabela 'contas_a_receber'. 
-- A tabela 't4' gerada pela sub consulta a quantidade total de parcela que é apresentada no campo 'descricao' da tabela 'contas_a_receber'. Nesse caso, foi tratado
-- nulos para o identificador.
-- Por fim, é filtrada a data_lancamento e valor para não inserir registros nulos na tabela 'lancamentos'.
--
INSERT INTO teste.lancamentos (tipo_recebimento, valor, valor_desconto, data_lancamento, data_recebimento, data_vencimento, total_parcelas, parcela_atual, cliente_venda_id) (
	select 
		CASE WHEN t1.forma_pagto = 'Cartão de Crédito' THEN 1
			 WHEN t1.forma_pagto = 'Cartão de Crédito Online' THEN 2
			 WHEN t1.forma_pagto = 'Cartão de Débito' THEN 3
			 WHEN t1.forma_pagto = 'Cheque' THEN 4
			 WHEN t1.forma_pagto = 'Dinheiro' THEN 5
			 WHEN t1.forma_pagto = 'Transferência' THEN 6
			 WHEN t1.forma_pagto = 'Transferência / Depósito' THEN 7
		END as tipo_recebimento
        ,t1.valor_bruto as valor, t1.taxa as valor_desconto,        
        STR_TO_DATE(t1.data_do_pagamento,'%d/%m/%Y') as data_lancamento
         ,STR_TO_DATE(t1.data_do_recebimento,'%d/%m/%Y') as data_recebimento, STR_TO_DATE(t1.data_do_vencimento,'%d/%m/%Y') as data_vencimento,
		 t4.total_parcelas as total_parcelas, t3.parcelaAtual as parcela_atual,
         SUBSTRING_INDEX(t1.descricao,' ',-1) as cliente_venda_id
	from contas_a_receber t1
	inner join (
		select TRIM(SUBSTRING_INDEX(descricao,' ',-1)) as id,  max(STR_TO_DATE(data_do_vencimento,'%d/%m/%Y')) as maxDtVenc
		from contas_a_receber
		group by 1
	) as t2
	on TRIM(SUBSTRING_INDEX(descricao,' ',-1)) = t2.id AND STR_TO_DATE(t1.data_do_vencimento,'%d/%m/%Y') = maxDtVenc
	inner join (
		-- TABELA: LANCAMENTOS -- COLUNA parcela_atual
		select SUBSTRING_INDEX(descricao,' ',-1) as cliente_venda_id, count(*) as parcelaAtual
		from contas_a_receber
		group by 1
	) as t3 on TRIM(SUBSTRING_INDEX(t1.descricao,' ',-1)) = t3.cliente_venda_id
	inner join (
		-- TABELA: LANCAMENTOS -- COLUNA total_parcelas
		select 
			case when SUBSTRING_INDEX(descricao,' ',-1) REGEXP '^[0-9]+\\.?[0-9]*$' then SUBSTRING_INDEX(descricao,' ',-1) else null
			end as cliente_venda_id
		, SUBSTRING_INDEX(SUBSTRING_INDEX(descricao,' ',1),'/',-1) as total_parcelas
		from contas_a_receber
		group by 1,2
	) as t4 on TRIM(SUBSTRING_INDEX(t1.descricao,' ',-1)) = t4.cliente_venda_id
    where STR_TO_DATE(t1.data_do_pagamento,'%d/%m/%Y') is not null AND t1.valor_bruto is not null
);

-- CONSULTA que faz inserção dos dados na tabela CLIENTE_CONTRATO
--
-- Faltou a referência do contrato. Por isso, a consulta não irá funcionar.
-- Foram criados identificadores para que seja possível inserir os registros no campo 'tipo_vigencia' da tabela 'cliente_contrato'. Porém, não foi possível identificar os 
-- registros na tabela 'teste.contrato' para cruzar os dados. Também foi utiliza o campo 'valor_padrao', mas não funcionou. A linha está comentada.
-- 'Anual' 			== 1
-- 'Gympass' 		== 2
-- 'GYMPASS Sessão' == 3
-- 'LIGHT - Anual' 	== 4
-- 'Mensal' 		== 5
-- 'Semestral' 		== 6
-- 'Trimestral' 	== 7
--
-- A tabela 't1' (teste.cliente_venda) contem o identificador da venda (t1.id).
-- A tabela 't2' (teste.cliente) com o identificador do usuario (t2.id). Foi utilizada essa tabela para buscar o nome do cliente.
-- A tabela 't3' gerada a partir da tabela 'exam-backup.tipo_vigencia' com informacoes relevantes do contrato feito pelo cliente como a data de inicio, data final e valor.
-- Por fim, foram filtrados os campos nulos com as informacoes de valor, data_inicial e data_final.
--
insert into teste.cliente_contrato (valor_contrato,data_inicio,data_vencimento,cliente_venda_id) (
	select t3.valor as valor_contrato, t3.data_inicial as data_inicio, t3.data_final as data_vencimento,t1.id as cliente_venda_id
	from teste.cliente_venda t1
	inner join teste.cliente t2 on t1.cliente_id = t2.id
	inner join (
		select atleta,data_inicial,data_final,valor,
			CASE WHEN recorrencia = 'Anual' THEN 1
			WHEN recorrencia = 'Gympass' THEN 2
			WHEN recorrencia = 'GYMPASS Sessão' THEN 3
			WHEN recorrencia = 'LIGHT - Anual' THEN 4
			WHEN recorrencia = 'Mensal' THEN 5
			WHEN recorrencia = 'Semestral' THEN 6
			WHEN recorrencia = 'Trimestral' THEN 7
			END as tipo_vigencia
		from detalhadas 
	) t3 on t2.nome = t3.atleta
	-- inner join teste.contrato t4 on t4.tipo_vigencia = t3.tipo_vigencia AND t4.valor_padrao = t3.valor
	WHERE t3.valor is not null AND  t3.data_inicial is not null AND t3.data_final is not null 
);