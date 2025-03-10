create table token_launch(
    memecoin_address TEXT,
    owner_address TEXT,
    network TEXT,
    block_hash TEXT,
    block_number BIGINT,
    block_timestamp TIMESTAMP,
    transaction_hash TEXT PRIMARY KEY,
    quote_token TEXT,
    exchange_name TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_supply TEXT,
    current_supply TEXT,
    liquidity_raised TEXT,
    threshold_liquidity TEXT,
    price TEXT,
    _cursor BIGINT,
    time_stamp TEXT,
    total_token_holded TEXT,
);

create table token_deploy(
    memecoin_address TEXT,
    network TEXT,
    block_hash TEXT,
    block_number BIGINT,
    block_timestamp TIMESTAMP,
    transaction_hash TEXT PRIMARY KEY,

    owner_address TEXT,
    name TEXT,
    symbol TEXT,
    initial_supply TEXT,
    total_supply TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    _cursor BIGINT,
    time_stamp TEXT


);

CREATE TABLE token_transactions (
    transfer_id TEXT PRIMARY KEY,
    network TEXT,
    block_hash TEXT,
    block_number BIGINT,
    block_timestamp TIMESTAMP,
    transaction_hash TEXT,
    memecoin_address TEXT,
    owner_address TEXT,
    last_price TEXT,
    quote_amount TEXT,
    coin_received TEXT,
    initial_supply TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_supply TEXT,
    current_supply TEXT,
    liquidity_raised TEXT,
    price TEXT,
    protocol_fee TEXT,
    amount NUMERIC,
    _cursor BIGINT,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('buy', 'sell')),
    time_stamp TEXT
);


create table unrugmeme_transfers(
    network TEXT,
    block_hash TEXT,
    block_number BIGINT,
    block_timestamp TIMESTAMP,
    transaction_hash TEXT,
    transfer_id TEXT unique PRIMARY KEY,
    from_address TEXT,
    to_address TEXT,
    memecoin_address TEXT,
    amount TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    _cursor BIGINT
);

create table unrugmeme_deploy(
    network TEXT,
    block_hash TEXT,
    block_number BIGINT,
    block_timestamp TIMESTAMP,
    transaction_hash TEXT,
    memecoin_address TEXT unique PRIMARY KEY,
    owner_address TEXT,
    name TEXT,
    symbol TEXT,
    initial_supply TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    _cursor BIGINT
);

create table unrugmeme_launch(
    network TEXT,
    block_hash TEXT,
    block_number BIGINT,
    block_timestamp TIMESTAMP,
    transaction_hash TEXT,
    memecoin_address TEXT unique PRIMARY KEY,
    quote_token TEXT,
    exchange_name TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    _cursor BIGINT
);


create table username_claimed(
    owner_address TEXT,
    network TEXT,
    block_hash TEXT,
    block_number BIGINT,
    block_timestamp TIMESTAMP,
    transaction_hash TEXT PRIMARY KEY,
    expiry TEXT,
    username TEXT,
    name TEXT,
    symbol TEXT,
    paid TEXT,
    quote_address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    _cursor BIGINT,
    time_stamp TEXT
);

create table username_changed(
    owner_address TEXT,
    network TEXT,
    block_hash TEXT,
    block_number BIGINT,
    block_timestamp TIMESTAMP,
    transaction_hash TEXT PRIMARY KEY,
    name TEXT,
    old_name TEXT,
    paid TEXT,
    quote_address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    _cursor BIGINT,
    time_stamp TEXT
);

create table renew_subscription(
    owner_address TEXT,
    network TEXT,
    block_hash TEXT,
    block_number BIGINT,
    block_timestamp TIMESTAMP,
    transaction_hash TEXT PRIMARY KEY,
    name TEXT,
    old_name TEXT,
    paid TEXT,
    quote_address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    _cursor BIGINT,
    time_stamp TEXT
);


create table shares_token_user(
    id TEXT,
    owner TEXT,
    token_address TEXT,
    total_token_holded TEXT,
    amount_owned TEXT,
    time_stamp DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    _cursor BIGINT

);
