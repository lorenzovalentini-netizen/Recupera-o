CREATE TABLE investidores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(11) UNIQUE NOT NULL
        CHECK (LENGTH(cpf) = 11),
    nivel_experiencia INTEGER DEFAULT 0
        CHECK (nivel_experiencia >= 0)
);


CREATE TABLE carteiras (
    id SERIAL PRIMARY KEY,
    investidor_id INTEGER NOT NULL,
    endereco_wallet VARCHAR(100) UNIQUE NOT NULL,
    rede_blockchain VARCHAR(50) NOT NULL,
    saldo_usd NUMERIC(18,2) NOT NULL
	  CHECK (saldo_usd > 0),
    status VARCHAR(20) DEFAULT 'ativa'
        CHECK (status IN ('ativa', 'em analise', 'bloqueada', 'pausada')),
    FOREIGN KEY (investidor_id) REFERENCES investidores(id)
);

CREATE TABLE corretoras (
    id SERIAL PRIMARY KEY,
    nome_exchange VARCHAR(100) NOT NULL,
    cnpj VARCHAR(14) UNIQUE NOT NULL
        CHECK (LENGTH(cnpj) = 14),
    email_suporte VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE criptomoedas (
    id SERIAL PRIMARY KEY,
    corretora_id INTEGER NOT NULL,
    nome_moeda VARCHAR(50) NOT NULL,
    preco_unitario_usd NUMERIC(18,2) NOT NULL
        CHECK (preco_unitario_usd > 0),
    categoria VARCHAR(30) DEFAULT 'Layer1'
        CHECK (categoria IN ('Layer1', 'DeFi', 'Memecoin', 'Stablecoin')),
    FOREIGN KEY (corretora_id) REFERENCES corretoras(id)
);

CREATE TABLE transacoes_cripto (
    id SERIAL PRIMARY KEY,
    carteira_id INTEGER NOT NULL,
    criptomoeda_id INTEGER NOT NULL,
    quantidade NUMERIC(18,8) NOT NULL
        CHECK (quantidade > 0),
    valor_pago NUMERIC(18,2) NOT NULL
        CHECK (valor_pago > 0),
    data_transacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (carteira_id) REFERENCES carteiras(id),
    FOREIGN KEY (criptomoeda_id) REFERENCES criptomoedas(id)
);


INSERT INTO investidores (nome, cpf, nivel_experiencia) VALUES
('Doctor Doom', '12345678901', 2),
('Celso Jacinto', '23456789012', 5),
('Emme White', '34567890123', 1),
('Tom Holland', '45678901234', 3),
('Pedro Alvares Cabral', '56789012345', 0);

INSERT INTO carteiras
(investidor_id, endereco_wallet, rede_blockchain, saldo_usd, status)
VALUES
(1, '0x71C000000000000000000000000000000000000A', 'Ethereum', 1500.00, 'ativa'),
(2, '0x72C000000000000000000000000000000000000B', 'Ethereum', 2500.00, 'em analise'),
(3, '0x73C000000000000000000000000000000000000C', 'Bitcoin', 800.00, 'bloqueada'),
(4, '0x74C000000000000000000000000000000000000D', 'Solana', 3200.00, 'pausada'),
(5, '0x75C000000000000000000000000000000000000E', 'Bitcoin', 1000.00, 'ativa');

INSERT INTO corretoras (nome_exchange, cnpj, email_suporte) VALUES
('Binance', '12345678000190', 'suporte@binance.com'),
('Coinbase', '23456789000191', 'suporte@coinbase.com'),
('Kraken', '34567890000192', 'suporte@kraken.com'),
('OKX', '45678901000193', 'suporte@okx.com'),
('Bybit', '56789012000194', 'suporte@bybit.com');

INSERT INTO criptomoedas
(corretora_id, nome_moeda, preco_unitario_usd, categoria)
VALUES
(1, 'Bitcoin', 95000.00, 'Layer1'),
(2, 'Ethereum', 3200.00, 'Layer1'),
(3, 'Uniswap', 12.50, 'DeFi'),
(4, 'Dogecoin', 0.25, 'Memecoin'),
(5, 'USDT', 1.00, 'Stablecoin');

INSERT INTO transacoes_cripto
(carteira_id, criptomoeda_id, quantidade, valor_pago)
VALUES
(3, 1, 0.01, 950.00),
(4, 2, 0.50, 1600.00),
(5, 3, 10.00, 125.00),
(6, 4, 1000.00, 250.00),
(7, 5, 500.00, 500.00);

SELECT
    c.endereco_wallet,
    c.rede_blockchain,
    c.saldo_usd,
    i.nome,
    i.cpf
FROM carteiras c
INNER JOIN investidores i
    ON c.investidor_id = i.id
WHERE c.status IN ('ativa', 'em analise');
SELECT
    co.nome_exchange,
    SUM(t.valor_pago) AS total_valor_pago
FROM transacoes_cripto t
INNER JOIN criptomoedas cr
    ON t.criptomoeda_id = cr.id
INNER JOIN corretoras co
    ON cr.corretora_id = co.id
GROUP BY co.nome_exchange;

SELECT
    co.nome_exchange,
    SUM(t.valor_pago) AS total_valor_pago
FROM transacoes_cripto t
INNER JOIN criptomoedas cr
    ON t.criptomoeda_id = cr.id
INNER JOIN corretoras co
    ON cr.corretora_id = co.id
GROUP BY co.nome_exchange;

SELECT
    c.endereco_wallet,
    cr.nome_moeda,
    t.quantidade,
    t.valor_pago,
    t.data_transacao
FROM transacoes_cripto t
INNER JOIN carteiras c
    ON t.carteira_id = c.id
INNER JOIN criptomoedas cr
    ON t.criptomoeda_id = cr.id
WHERE t.valor_pago > 500
ORDER BY t.valor_pago DESC;

CREATE VIEW vw_painel_carteiras AS
SELECT
    c.endereco_wallet,
    c.rede_blockchain,
    c.status,
    c.saldo_usd,
    i.nome,
    i.cpf
FROM carteiras c
INNER JOIN investidores i
    ON c.investidor_id = i.id;

CREATE VIEW vw_investimento_total_carteiras AS
SELECT
    c.id,
    c.endereco_wallet,
    c.saldo_usd,
    COALESCE(SUM(t.quantidade), 0) AS quantidade_total,
    COALESCE(SUM(t.valor_pago), 0) AS custo_total
FROM carteiras c
LEFT JOIN transacoes_cripto t
    ON c.id = t.carteira_id
GROUP BY c.id, c.endereco_wallet, c.saldo_usd;