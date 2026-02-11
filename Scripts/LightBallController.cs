using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[ExecuteInEditMode]
public class LightBallController : MonoBehaviour
{
    [Serializable]
    public class SignalGenerator
    {
        [Tooltip("信号桶大小（通常等于球数量），用于确定循环周期。")]
        public int Bucket;

        [Tooltip("信号偏移量，用于整体平移信号的起点。")]
        public int Offset;

        [Tooltip("是否启用往返模式（Yoyo）。信号将前后循环。")]
        public bool Yoyo;

        [Tooltip("是否启用反向模式（Rewind）。信号顺序镜像反转。")]
        public bool Rewind;

        [Tooltip("信号重复次数，大于1时可压缩节奏。")]
        public int Repeat;

        [Tooltip("该信号对应的材质索引（SignalMaterials 数组中的序号）。")]
        public int Target;

        public int Generate(int seed)
        {
            int input;
            int v;
            if (Repeat > 1)
                input = seed / Repeat;
            else
                input = seed;

            if (Rewind)
                input = Bucket - 1 - input - Offset;
            else
                input = input + Offset;

            if (Yoyo)
            {
                var half = Bucket / 2;
                v = (input + half) % Bucket - half;
                v = Math.Abs(v < 0 ? v + 1 : v);
            }
            else
            {
                v = (input % Bucket + Bucket) % Bucket;
            }

            return v;
        }
    }

    [Serializable]
    public class SignalMap
    {
        [Tooltip("信号周期长度。>0 时表示每隔 Period 个球触发一次。")]
        public int Period;

        [Tooltip("桶大小（由球数量自动赋值）。")]
        public int Bucket;

        public bool Map(int sig, int k)
        {
            k %= Bucket;
            if (Period > 0)
                return ((sig + Bucket - k) % Period) == 0;
            else
                return k == sig;
        }
    }

    [Serializable]
    public class SignalStage
    {
        [Tooltip("该阶段使用的信号生成器数组。")]
        public SignalGenerator[] Generators;

        [Tooltip("信号映射规则。用于决定哪些球响应信号。")]
        public SignalMap SignalMap;

        [Tooltip("是否闪烁模式（激活后再灭一次）。")]
        public bool Blink;

        [Tooltip("阶段时长（执行步数）。")]
        public int Length;
    }

    [Header("🔹 材质与信号设置")]
    [Tooltip("默认材质（所有球体的基础状态）。")]
    public Material Material0;

    [Tooltip("信号材质数组，不同索引代表不同信号效果。")]
    public Material[] SignalMaterials;

    [Tooltip("每次信号的持续时间（毫秒）。")]
    public int SignalDurationMs = 500;

    [Tooltip("信号阶段配置。可堆叠多个阶段组成灯光序列。")]
    public SignalStage[] Stages;

    [Header("🔹 布局控制参数")]
    [Tooltip("圆形或螺旋的半径。")]
    public float Radius = 5f;

    [Tooltip("螺旋模式的总高度。")]
    public float SpiralHeight = 5f;

    [Tooltip("螺旋模式的圈数。")]
    public int SpiralTurns = 3;

    [Tooltip("波浪模式的波峰高度。")]
    public float WaveAmplitude = 1.5f;

    [Tooltip("网格模式的行数。")]
    public int GridRows = 3;

#if UNITY_EDITOR
    public enum ArrangeMode
    {
        CircleXY,
        CircleXZ,
        Line,
        Grid,
        Sphere,
        Spiral,
        Wave
    }

    [Tooltip("当前选择的布局模式。")]
    public ArrangeMode LayoutMode = ArrangeMode.CircleXY;
#endif

    private readonly List<MeshRenderer> _balls = new();

    private void CollectBalls()
    {
        _balls.Clear();
        _balls.AddRange(
            GetComponentsInChildren<MeshRenderer>()
                .Where(x => x.gameObject != this.gameObject)
                .OrderBy(x => x.name)
        );
    }

    private void Start()
    {
        CollectBalls();
        foreach (var item in _balls)
            item.sharedMaterial = Material0;
    }

    // ---------- 运行信号动画（改用 Coroutine） ----------
    // 在 Inspector 右上角的三点菜单或组件右键可以看到这些 ContextMenu 项
    [ContextMenu("Run Signal Sequence")]
    public void Do()
    {
        // 停止之前的协程（如果有）
        StopAllCoroutines();
        StartCoroutine(LifeTimeCoroutine());
    }

    [ContextMenu("Stop Signal Sequence")]
    public void StopSequence()
    {
        StopAllCoroutines();
        // 恢复默认材质
        CollectBalls();
        foreach (var b in _balls)
            b.sharedMaterial = Material0;
    }

    private IEnumerator LifeTimeCoroutine()
    {
        CollectBalls();
        if (Stages == null) yield break;

        foreach (var stage in Stages)
        {
            if (stage == null) continue;
            if (stage.SignalMap != null)
                stage.SignalMap.Bucket = Math.Max(1, _balls.Count);

            for (int i = 0; i < stage.Length; i++)
            {
                var signals = stage.Generators?.Select(x => (x.Generate(i), x.Target)) ?? Enumerable.Empty<(int, int)>();
                yield return StartCoroutine(OnSignalCoroutine(i, stage.Blink, signals, stage.SignalMap));
            }
        }
    }

    private IEnumerator OnSignalCoroutine(int seed, bool blink, IEnumerable<(int, int)> signals, SignalMap signalMap)
    {
        if (signalMap == null) yield break;
        CollectBalls();

        // 激活对应信号材质
        for (int i = 0; i < _balls.Count; i++)
        {
            bool applied = false;
            foreach (var sig in signals)
            {
                if (signalMap.Map(sig.Item1, i))
                {
                    int matIndex = sig.Item2;
                    if (SignalMaterials != null && matIndex >= 0 && matIndex < SignalMaterials.Length)
                        _balls[i].sharedMaterial = SignalMaterials[matIndex];
                    applied = true;
                    break;
                }
            }
            if (!applied)
            {
                // 不匹配任何信号时保持当前（或默认）
            }
        }

        // 等待 duration（把 ms 转为秒）
        float seconds = SignalDurationMs / 1000f;
        yield return new WaitForSeconds(seconds);

        // 恢复默认材质
        for (int i = 0; i < _balls.Count; i++)
        {
            _balls[i].sharedMaterial = Material0;
        }

        if (blink)
            yield return new WaitForSeconds(seconds);
    }

    // ---------- 布局（ContextMenu 调用） ----------
#if UNITY_EDITOR
    [ContextMenu("Arrange Layout")]
    public void ArrangeLayout()
    {
        CollectBalls();
        switch (LayoutMode)
        {
            case ArrangeMode.CircleXY:
                ArrangeCircleXY();
                break;
            case ArrangeMode.CircleXZ:
                ArrangeCircleXZ();
                break;
            case ArrangeMode.Line:
                ArrangeLine();
                break;
            case ArrangeMode.Grid:
                ArrangeGrid();
                break;
            case ArrangeMode.Sphere:
                ArrangeSphere();
                break;
            case ArrangeMode.Spiral:
                ArrangeSpiral();
                break;
            case ArrangeMode.Wave:
                ArrangeWave();
                break;
        }
    }
#endif

#if UNITY_EDITOR
    private void ArrangeCircleXY()
    {
        int count = _balls.Count;
        if (count == 0) return;
        float angle = 360f / count;
        Vector3 pos0 = transform.position + transform.right * Radius;

        for (int i = 0; i < count; i++)
        {
            var rot = Quaternion.AngleAxis(angle * i, transform.forward);
            _balls[i].transform.position = rot * (pos0 - transform.position) + transform.position;
            EditorUtility.SetDirty(_balls[i].gameObject);
        }
    }

    private void ArrangeCircleXZ()
    {
        int count = _balls.Count;
        if (count == 0) return;
        float angle = 360f / count;
        Vector3 pos0 = transform.position + transform.right * Radius;

        for (int i = 0; i < count; i++)
        {
            var rot = Quaternion.AngleAxis(angle * i, Vector3.up);
            _balls[i].transform.position = rot * (pos0 - transform.position) + transform.position;
            EditorUtility.SetDirty(_balls[i].gameObject);
        }
    }

    private void ArrangeLine()
    {
        int count = _balls.Count;
        if (count <= 1) return;
        float interval = 2 * Radius / (count - 1);
        Vector3 pos0 = transform.position - transform.right * Radius;

        for (int i = 0; i < count; i++)
        {
            _balls[i].transform.position = pos0 + transform.right * interval * i;
            EditorUtility.SetDirty(_balls[i].gameObject);
        }
    }

    private void ArrangeGrid()
    {
        int count = _balls.Count;
        if (count == 0) return;
        int cols = Mathf.CeilToInt((float)count / GridRows);
        float spacingX = (2 * Radius) / Mathf.Max(1, cols - 1);
        float spacingY = (2 * Radius) / Mathf.Max(1, GridRows - 1);
        Vector3 start = transform.position - transform.right * Radius - transform.up * Radius;

        for (int i = 0; i < count; i++)
        {
            int row = i / cols;
            int col = i % cols;
            Vector3 pos = start + transform.right * (col * spacingX) + transform.up * (row * spacingY);
            _balls[i].transform.position = pos;
            EditorUtility.SetDirty(_balls[i].gameObject);
        }
    }

    private void ArrangeSphere()
    {
        int count = _balls.Count;
        if (count == 0) return;
        float offset = 2f / count;
        float increment = Mathf.PI * (3 - Mathf.Sqrt(5)); // 黄金角分布

        for (int i = 0; i < count; i++)
        {
            float y = ((i * offset) - 1) + (offset / 2);
            float r = Mathf.Sqrt(1 - y * y);
            float phi = i * increment;

            Vector3 pos = new Vector3(Mathf.Cos(phi) * r, y, Mathf.Sin(phi) * r) * Radius + transform.position;
            _balls[i].transform.position = pos;
            EditorUtility.SetDirty(_balls[i].gameObject);
        }
    }

    private void ArrangeSpiral()
    {
        int count = _balls.Count;
        if (count == 0) return;
        float angleStep = 360f * SpiralTurns / count;
        float heightStep = SpiralHeight / count;

        for (int i = 0; i < count; i++)
        {
            float angle = i * angleStep * Mathf.Deg2Rad;
            float y = (i - count / 2f) * heightStep;
            Vector3 pos = transform.position + new Vector3(Mathf.Cos(angle) * Radius, y, Mathf.Sin(angle) * Radius);
            _balls[i].transform.position = pos;
            EditorUtility.SetDirty(_balls[i].gameObject);
        }
    }

    private void ArrangeWave()
    {
        int count = _balls.Count;
        if (count == 0) return;
        float interval = 2 * Radius / (count - 1);
        Vector3 start = transform.position - transform.right * Radius;

        for (int i = 0; i < count; i++)
        {
            float x = i * interval;
            float y = Mathf.Sin(i * 0.5f) * WaveAmplitude;
            Vector3 pos = start + transform.right * x + transform.up * y;
            _balls[i].transform.position = pos;
            EditorUtility.SetDirty(_balls[i].gameObject);
        }
    }
#endif
}
