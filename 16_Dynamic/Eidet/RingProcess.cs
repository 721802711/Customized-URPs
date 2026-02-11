using UnityEngine;
using UnityEngine.UI;
using TMPro;

[ExecuteAlways]
public class RingProcess : MonoBehaviour
{
    [Header("进度条组件 (Image - Filled 模式)")]
    public Image progressImage;

    [Header("进度百分比文字 (TextMeshPro)")]
    public TMP_Text progressText;

    [Header("动画速度 (每秒百分比)")]
    public float speed = 50f;

    [Header("目标进度 0-100")]
    [Range(0, 100)]
    public float targetProcess = 100f;

    [Header("是否自动播放动画")]
    public bool autoPlay = true;

    [Header("渐变颜色设置 (4段)")]
    public Color colorA = new Color(0.1f, 0.9f, 0.2f);   // 0% 起点
    public Color colorB = new Color(0.9f, 0.9f, 0.2f);   // 25% 中低
    public Color colorC = new Color(0.9f, 0.6f, 0.2f);   // 60% 中高
    public Color colorD = new Color(0.9f, 0.1f, 0.1f);   // 100% 终点

    [Tooltip("颜色A-B-C-D对应的进度节点位置 (0~1之间)")]
    [Range(0f, 1f)] public float colorBPosition = 0.25f;
    [Range(0f, 1f)] public float colorCPosition = 0.6f;

    private float currentAmount = 0f;
    private float lastTargetProcess;

    void Start()
    {
        if (progressImage == null)
            progressImage = GetComponentInChildren<Image>();
        if (progressText == null)
            progressText = GetComponentInChildren<TMP_Text>();

        lastTargetProcess = targetProcess;
        UpdateUI();
    }

    void Update()
    {
        #if UNITY_EDITOR
        if (!Application.isPlaying)
        {
            UpdateUI();
            lastTargetProcess = targetProcess;
            return;
        }
        #endif

        if (autoPlay)
        {
            if (Mathf.Abs(currentAmount - targetProcess) > 0.01f)
            {
                currentAmount = Mathf.MoveTowards(currentAmount, targetProcess, speed * Time.deltaTime);
                UpdateUI();
            }
        }
        else
        {
            // 如果在 Inspector 里手动修改 targetProcess
            if (!Mathf.Approximately(lastTargetProcess, targetProcess))
            {
                currentAmount = targetProcess;
                UpdateUI();
                lastTargetProcess = targetProcess;
            }
        }
    }

    /// <summary>
    /// 外部设置目标进度 (0~100)
    /// </summary>
    public void SetProgress(float value)
    {
        targetProcess = Mathf.Clamp(value, 0, 100);
        if (!autoPlay)
        {
            currentAmount = targetProcess;
            UpdateUI();
        }
    }

    /// <summary>
    /// 更新图片填充与文字
    /// </summary>
    private void UpdateUI()
    {
        float normalized = Mathf.Clamp01(currentAmount / 100f);

        if (progressImage != null)
        {
            progressImage.fillAmount = normalized;
            progressImage.color = EvaluateColor(normalized);
        }

        if (progressText != null)
        {
            progressText.text = $"{Mathf.RoundToInt(currentAmount)}%";
            // 文字颜色保持固定，不随进度条变化
        }
    }

    /// <summary>
    /// 根据当前进度插值4段颜色
    /// </summary>
    private Color EvaluateColor(float t)
    {
        if (t <= colorBPosition)
        {
            float lerp = Mathf.InverseLerp(0f, colorBPosition, t);
            return Color.Lerp(colorA, colorB, lerp);
        }
        else if (t <= colorCPosition)
        {
            float lerp = Mathf.InverseLerp(colorBPosition, colorCPosition, t);
            return Color.Lerp(colorB, colorC, lerp);
        }
        else
        {
            float lerp = Mathf.InverseLerp(colorCPosition, 1f, t);
            return Color.Lerp(colorC, colorD, lerp);
        }
    }
}
