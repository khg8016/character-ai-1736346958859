-- Drop existing trigger and function
DROP TRIGGER IF EXISTS store_buyer_snapshot_trigger ON purchased_prototypes;
DROP FUNCTION IF EXISTS store_buyer_snapshot();

-- Create improved function to store buyer details with better error handling
CREATE OR REPLACE FUNCTION store_buyer_snapshot()
RETURNS trigger AS $$
DECLARE
  v_buyer_name text;
  v_buyer_display_id text;
BEGIN
  -- Get buyer details with better error handling
  SELECT 
    COALESCE(full_name, display_id),
    display_id
  INTO v_buyer_name, v_buyer_display_id
  FROM profiles
  WHERE id = NEW.user_id;

  -- Log the values for debugging
  RAISE NOTICE 'Storing snapshot for purchase %, buyer_id %, name %, display_id %',
    NEW.id, NEW.user_id, v_buyer_name, v_buyer_display_id;

  -- Insert snapshot with guaranteed non-null values
  INSERT INTO purchase_snapshots (
    purchase_id,
    buyer_id,
    buyer_name,
    buyer_display_id
  ) VALUES (
    NEW.id,
    NEW.user_id,
    COALESCE(v_buyer_name, 'Anonymous User'),
    COALESCE(v_buyer_display_id, 'anonymous')
  );
  
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log any errors
  RAISE WARNING 'Error in store_buyer_snapshot: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
CREATE TRIGGER store_buyer_snapshot_trigger
  AFTER INSERT ON purchased_prototypes
  FOR EACH ROW
  EXECUTE FUNCTION store_buyer_snapshot();

-- Update existing snapshots
UPDATE purchase_snapshots ps
SET 
  buyer_name = COALESCE(p.full_name, p.display_id, 'Anonymous User'),
  buyer_display_id = COALESCE(p.display_id, 'anonymous')
FROM profiles p
WHERE ps.buyer_id = p.id;

-- Add NOT NULL constraints
ALTER TABLE purchase_snapshots
  ALTER COLUMN buyer_name SET NOT NULL,
  ALTER COLUMN buyer_display_id SET NOT NULL;