-- try to compare the autotune best result with hourly run.
CREATE OR REPLACE VIEW
  `DiffWithBest` SQL SECURITY INVOKER AS
SELECT
  view1.JobReference,
  view1.Device,
  view1.Model,
  view1.Dataset,
  view1.InputLen,
  view1.OutputLen,
  view1.TensorParallelSize,
  view1.MaxModelLen,
  view1.Backend,

  view1.Throughput AS BestThroughput,
  view2.Throughput AS HourlyThroughput,

  -- tuned
  view1.MaxNumSeqs as BestMaxNumSeqs,
  view1.MaxNumBatchedTokens as BestMaxNumBatchedTokens,
  view1.NumPrompts as BestNumPrompts,
  view2.MaxNumSeqs as HourlyMaxNumSeqs,
  view2.MaxNumBatchedTokens as HourlyMaxNumBatchedTokens,
  view2.NumPrompts as HourlyNumPrompts  
FROM
  AutoTuneBestResult AS view1
JOIN
  HourlyRunForAutotune AS view2
ON
  view1.JobReference = view2.JobReference AND
  view1.Device = view2.Device AND
  view1.Model = view2.Model AND
  view1.Dataset = view2.Dataset AND
  view1.InputLen = view2.InputLen AND
  view1.OutputLen = view2.OutputLen AND
  view1.TensorParallelSize = view2.TensorParallelSize AND
  view1.MaxModelLen = view2.MaxModelLen AND
  view1.Backend = view2.Backend
WHERE  
  view1.Throughput > view2.Throughput  
