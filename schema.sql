-- dont create too many columns, focus more on the detail accuracies

-- 1. Users Table
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    income_range TEXT,
    financial_goals TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Debts Table
CREATE TABLE debts (
    debt_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),
    creditor TEXT NOT NULL,
    balance NUMERIC(12,2) NOT NULL,
    interest_rate NUMERIC(5,2) NOT NULL,
    min_payment NUMERIC(12,2),
    payment_due_date DATE,
    last_payment_amount NUMERIC(12,2),
    settlement_status TEXT CHECK (settlement_status IN ('open', 'closed', 'disputed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Payments Table
CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    debt_id UUID REFERENCES debts(debt_id),
    amount NUMERIC(12,2) NOT NULL,
    payment_date DATE NOT NULL,
    method TEXT CHECK (method IN ('manual', 'auto', 'mutual_aid')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trigger Function for Tracking Repayments
CREATE OR REPLACE FUNCTION update_debt_balance() RETURNS TRIGGER AS $$
BEGIN
    UPDATE debts SET balance = balance - NEW.amount
    WHERE debt_id = NEW.debt_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger on Payments Insert
CREATE TRIGGER trg_update_debt_balance
AFTER INSERT ON payments
FOR EACH ROW
EXECUTE FUNCTION update_debt_balance();

-- 4. AI Recommendations Table
CREATE TABLE ai_recommendations (
    rec_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),
    strategy TEXT CHECK (strategy IN ('snowball', 'avalanche')),
    suggestion TEXT,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Fraud Support Tables
CREATE TABLE mutual_aid (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),
    amount_requested NUMERIC(12,2),
    reason TEXT,
    approved BOOLEAN DEFAULT FALSE,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE fraud_disputes (
    dispute_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    debt_id UUID REFERENCES debts(debt_id),
    description TEXT,
    status TEXT CHECK (status IN ('pending', 'resolved', 'rejected')),
    filed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Snowball
CREATE OR REPLACE VIEW snowball_view AS
SELECT * FROM debts
ORDER BY balance ASC;

-- 7. Avalanche 
CREATE OR REPLACE VIEW avalanche_view AS
SELECT * FROM debts
ORDER BY interest_rate DESC, balance ASC;
