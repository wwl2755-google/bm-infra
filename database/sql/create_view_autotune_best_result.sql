CREATE OR REPLACE VIEW
  `AutoTuneBestResult` SQL SECURITY INVOKER AS
SELECT
  r.JobReference,
  r.Model,
  r.CodeHash,
  r.Device,
  r.Dataset,
  r.Throughput,
  r.MaxNumSeqs,
  r.MaxNumBatchedTokens,
  r.NumPrompts,
  r.TensorParallelSize,
  r.MaxModelLen,
  r.RunType,
  r.InputLen,
  r.OutputLen,
  r.ExpectedETEL,
  CASE
    WHEN r.Device  = 'b200-8'  THEN 'b200-8' 
    WHEN r.RunType = 'AUTOTUNE' THEN 'torchxla'
    WHEN r.RunType = 'AUTOTUNE_TORCHAX' THEN 'torchax'
    WHEN r.RunType = 'AUTOTUNE_JAX' THEN 'jax'
    WHEN r.RunType = 'AUTOTUNE_AX_JAX' THEN 'torchax-jax'    
    ELSE 'unknown'
  END AS Backend
FROM RunRecord r
WHERE r.RunType IN ('AUTOTUNE', 'AUTOTUNE_TORCHAX', 'AUTOTUNE_JAX', 'AUTOTUNE_AX_JAX')
  AND r.Status IN ('COMPLETED', 'FAILED')
  AND r.CreatedTime >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 3 DAY)
  AND r.Throughput = (
    SELECT MAX(r2.Throughput)
    FROM RunRecord r2
    WHERE r2.JobReference = r.JobReference
      AND r2.Model = r.Model
      AND r2.CodeHash = r.CodeHash
      AND r2.Device = r.Device
      AND r2.InputLen = r.InputLen
      AND r2.OutputLen = r.OutputLen
      AND r2.ExpectedETEL = r.ExpectedETEL
      AND r2.RunType IN ('AUTOTUNE', 'AUTOTUNE_TORCHAX', 'AUTOTUNE_JAX', 'AUTOTUNE_AX_JAX')
      AND r2.RunType = r.RunType
      AND r2.Status IN ('COMPLETED', 'FAILED')
      AND r2.CreatedTime >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 3 DAY)
  )
ORDER BY r.JobReference;
