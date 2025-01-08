/*
  # Add credits for existing users

  1. Creates credit records for existing users who don't have them yet
  2. Adds initial transaction records for these users
*/

-- Add credits for existing users who don't have credit records
INSERT INTO user_credits (user_id, balance)
SELECT id, 100
FROM auth.users
WHERE id NOT IN (SELECT user_id FROM user_credits)
ON CONFLICT (user_id) DO NOTHING;

-- Add initial transaction records for these users
INSERT INTO credit_transactions (user_id, amount, type, description)
SELECT id, 100, 'charge', '회원가입 보너스 크레딧'
FROM auth.users
WHERE id NOT IN (
  SELECT user_id 
  FROM credit_transactions 
  WHERE type = 'charge' AND description = '회원가입 보너스 크레딧'
);