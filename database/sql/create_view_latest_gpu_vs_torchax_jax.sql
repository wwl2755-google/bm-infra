CREATE OR REPLACE VIEW
  `LatestGPUvsTorchaxJax` SQL SECURITY INVOKER AS
SELECT
  j.Model,
  j.JobReference,
  STRING_AGG(DISTINCT j.Device, ', ') AS Devices,
  MAX(CASE
      WHEN j.Device = 'h100-8' THEN j.Throughput
      ELSE NULL
  END
    ) AS GPUThroughput,
  MAX(CASE
      WHEN j.Device IN ('v6e-8', 'v6e-1') THEN j.Throughput
      ELSE NULL
  END
    ) AS TPUThroughput,
  MAX(CASE
      WHEN j.Device = 'h100-8' THEN j.MedianITL
      ELSE NULL
  END
    ) AS GPUMedianITL,
  MAX(CASE
      WHEN j.Device IN ('v6e-8', 'v6e-1') THEN j.MedianITL
      ELSE NULL
  END
    ) AS TPUMedianITL,
  MAX(CASE
      WHEN j.Device = 'h100-8' THEN j.MedianTPOT
      ELSE NULL
  END
    ) AS GPUMedianTPOT,
  MAX(CASE
      WHEN j.Device IN ('v6e-8', 'v6e-1') THEN j.MedianTPOT
      ELSE NULL
  END
    ) AS TPUMedianTPOT,
  MAX(CASE
      WHEN j.Device = 'h100-8' THEN j.MedianTTFT
      ELSE NULL
  END
    ) AS GPUMedianTTFT,
  MAX(CASE
      WHEN j.Device IN ('v6e-8', 'v6e-1') THEN j.MedianTTFT
      ELSE NULL
  END
    ) AS TPUMedianTTFT,
  MAX(CASE
      WHEN j.Device = 'h100-8' THEN j.MedianETEL
      ELSE NULL
  END
    ) AS GPUMedianETEL,
  MAX(CASE
      WHEN j.Device IN ('v6e-8', 'v6e-1') THEN j.MedianETEL
      ELSE NULL
  END
    ) AS TPUMedianETEL,
  MAX(CASE
      WHEN j.Device = 'h100-8' THEN j.P99ITL
      ELSE NULL
  END
    ) AS GPUP99ITL,
  MAX(CASE
      WHEN j.Device IN ('v6e-8', 'v6e-1') THEN j.P99ITL
      ELSE NULL
  END
    ) AS TPUP99ITL,
  MAX(CASE
      WHEN j.Device = 'h100-8' THEN j.P99TPOT
      ELSE NULL
  END
    ) AS GPUP99TPOT,
  MAX(CASE
      WHEN j.Device IN ('v6e-8', 'v6e-1') THEN j.P99TPOT
      ELSE NULL
  END
    ) AS TPUP99TPOT,
  MAX(CASE
      WHEN j.Device = 'h100-8' THEN j.P99TTFT
      ELSE NULL
  END
    ) AS GPUP99TTFT,
  MAX(CASE
      WHEN j.Device IN ('v6e-8', 'v6e-1') THEN j.P99TTFT
      ELSE NULL
  END
    ) AS TPUP99TTFT,
  MAX(CASE
      WHEN j.Device = 'h100-8' THEN j.P99ETEL
      ELSE NULL
  END
    ) AS GPUP99ETEL,
  MAX(CASE
      WHEN j.Device IN ('v6e-8', 'v6e-1') THEN j.P99ETEL
      ELSE NULL
  END
    ) AS TPUP99ETEL
FROM (
  SELECT
    f.Model,
    f.JobReference,
    f.Device,
    f.Throughput,
    f.MedianITL,
    f.MedianTPOT,
    f.MedianTTFT,
    f.MedianETEL,
    f.P99ITL,
    f.P99TPOT,
    f.P99TTFT,
    f.P99ETEL
  FROM
    HourlyRunAll30Days f
  JOIN (
    SELECT
      p.Model,
      MAX(p.JobReference) AS LatestJobRef
    FROM (
      SELECT
        q.Model,
        q.JobReference
      FROM
        HourlyRunAll30Days q
      WHERE
        q.Status = 'COMPLETED'
        AND ( (q.Device = 'h100-8'
            AND q.RunType = 'HOURLY')
          OR (q.Device IN ('v6e-8',
              'v6e-1')
            AND q.RunType = 'HOURLY_AX_JAX') )
      GROUP BY
        q.Model,
        q.JobReference
      HAVING
        COUNT(DISTINCT q.Device) >= 2 ) p
    GROUP BY
      p.Model ) latest
  ON
    f.Model = latest.Model
    AND f.JobReference = latest.LatestJobRef
  WHERE
    f.Status = 'COMPLETED'
    AND ( (f.Device = 'h100-8'
        AND f.RunType = 'HOURLY')
      OR (f.Device IN ('v6e-8',
          'v6e-1')
        AND f.RunType = 'HOURLY_AX_JAX') ) ) j
GROUP BY
  j.Model,
  j.JobReference
ORDER BY
  j.Model;