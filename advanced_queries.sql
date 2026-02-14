-- Advanced reporting & maintenance queries for Credit Alchemist data

-- 1. Aggregate debt metrics: outstanding balance, avg interest, minimums
SELECT
    COUNT(*)                          AS debt_count,
    SUM(balance)                      AS total_outstanding_balance,
    AVG(interest_rate)                AS average_interest_rate,
    SUM(minimum_payment)              AS total_minimum_payment
FROM debts;

-- 2. Next 30-day debt obligations ordered by due date
SELECT
    creditor,
    balance,
    minimum_payment,
    due_date
FROM debts
WHERE due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
ORDER BY due_date ASC;

-- 3. Debt payoff priority list (avalanche: highest APR first)
SELECT
    creditor,
    balance,
    interest_rate,
    minimum_payment,
    ROW_NUMBER() OVER (ORDER BY interest_rate DESC, balance DESC) AS avalanche_rank
FROM debts;

-- 4. Credit-card utilization and risk flags
SELECT
    name,
    creditor_name,
    current_balance,
    credit_limit,
    ROUND((current_balance / NULLIF(credit_limit, 0)) * 100, 2) AS utilization_pct,
    past_due_amount,
    amount_over_limit,
    CASE
        WHEN amount_over_limit > 0 THEN 'over_limit'
        WHEN past_due_amount > 0 THEN 'past_due'
        WHEN (current_balance / NULLIF(credit_limit, 0)) > 0.9 THEN 'high_utilization'
        ELSE 'healthy'
    END AS risk_label
FROM credit_cards
ORDER BY utilization_pct DESC NULLS LAST;

-- 5. Minimum payments due soon for credit cards
SELECT
    name,
    minimum_payment_due,
    minimum_payment_due_date
FROM credit_cards
WHERE minimum_payment_due_date < CURRENT_DATE + INTERVAL '14 days'
ORDER BY minimum_payment_due_date ASC;

-- 6. Chat activity summary (messages per session)
SELECT
    cs.id                                                   AS session_id,
    cs.name                                                 AS session_name,
    COUNT(cm.id)                                            AS message_count,
    MIN(cm.timestamp)                                       AS first_message_at,
    MAX(cm.timestamp)                                       AS last_message_at
FROM chat_sessions cs
LEFT JOIN chat_messages cm ON cm.session_id = cs.id
GROUP BY cs.id, cs.name
ORDER BY last_message_at DESC NULLS LAST;

-- 7. Daily chat volume trend over past 14 days
SELECT
    DATE_TRUNC('day', timestamp) AS chat_day,
    COUNT(*)                    AS messages_sent
FROM chat_messages
WHERE timestamp >= CURRENT_DATE - INTERVAL '14 days'
GROUP BY chat_day
ORDER BY chat_day DESC;

-- 8. Most recent updates across core tables
SELECT 'debts' AS table_name, MAX(updated_at) AS last_updated FROM debts
UNION ALL
SELECT 'credit_cards', MAX(updated_at) FROM credit_cards
UNION ALL
SELECT 'chat_sessions', MAX(updated_at) FROM chat_sessions;
