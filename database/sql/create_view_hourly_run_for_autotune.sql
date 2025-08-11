-- This is same pattern as create_view_autotune_best_result.sql.
CREATE OR REPLACE VIEW
  `HourlyRunForAutotune` SQL SECURITY INVOKER AS
SELECT
  r.JobReference,
  r.Model,
  r.CodeHash,
  r.Device,
  r.Throughput,
  r.MaxNumSeqs,
  r.RunType,
  r.MaxNumBatchedTokens,
  r.TensorParallelSize,
  r.MaxModelLen,
  r.NumPrompts,
  r.Dataset,
  r.InputLen,
  r.OutputLen,
  CASE
    WHEN r.Device  = 'b200-8'  THEN 'b200-8' 
    WHEN r.RunType = 'HOURLY' THEN 'torchxla'
    WHEN r.RunType = 'HOURLY_TORCHAX' THEN 'torchax'
    WHEN r.RunType = 'HOURLY_JAX' THEN 'jax'
    WHEN r.RunType = 'HOURLY_AX_JAX' THEN 'torchax-jax'
    ELSE 'unknown'
  END AS Backend  
FROM RunRecord r
WHERE r.RunType in ('HOURLY', 'HOURLY_TORCHAX', 'HOURLY_JAX', 'HOURLY_AX_JAX')
  AND r.Status IN ('COMPLETED', 'FAILED')
  AND r.CreatedTime >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 3 DAY)
  AND r.Throughput = (
    SELECT MAX(r2.Throughput)
    FROM RunRecord r2
    WHERE r2.JobReference = r.JobReference
      AND r2.Model = r.Model
      AND r2.CodeHash = r.CodeHash
      AND r2.Device = r.Device
      AND r2.RunType in ('HOURLY', 'HOURLY_TORCHAX', 'HOURLY_JAX', 'HOURLY_AX_JAX')
      AND r2.Dataset = r.Dataset
      AND r2.Status IN ('COMPLETED', 'FAILED')
      AND r2.CreatedTime >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 3 DAY)
  )
ORDER BY r.JobReference;
