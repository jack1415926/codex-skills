---
name: frontend-jank-debugging
description: "Debug web animation jank / stutter on dynamic content (card reveals, modals, gacha). Layered-diagnosis checklist for the four stacked jank sources, plus pitfalls when extracting browser-generated CSS to static files (agent-browser JSON quoting, CSSOM escape serialization, file:// opaque origins, cascade-order regressions)."
---

# frontend-jank-debugging

交互动画卡顿排查参考卡。来自幻姬物语抽卡卡顿实战：卡顿是**多层叠加**的，症状随每层修复而变化——修复一层后重新观察症状规律，是核心方法。

## 一、四层卡顿源（按频率排查）

| 层 | 判定特征 | 解法 |
|----|---------|------|
| 1. 图片懒解码 | 卡顿与「该图片是否第一次出现」相关，随机 | 在揭晓前的等待窗口（加载动画/过渡期）用 `img.decode()` 预热即将展示的图片 |
| 2. 运行时 CSS 编译器 | 卡顿与「DOM 变更」相关，与元素类型无关 | Tailwind Play CDN / @tailwindcss/browser 用 MutationObserver 在每次 DOM 变更时全文档重扫——动态内容页面禁用，导出静态 CSS |
| 3. filter / box-shadow 动画 | 卡顿与该类元素强相关，或揭晓瞬间一次性卡 | `filter: drop-shadow` 会在首次出现帧对大透明图做一次性光栅化；box-shadow 过渡每帧重绘整个元素。光晕改用伪元素径向渐变，动画只留 transform/opacity |
| 4. getBoundingClientRect 强制布局 | 卡顿轻微且持续 | 能免则免（把子元素放进定位父容器内，消除测量） |

- **分层剥离法**：症状规律是最好的诊断工具。修一层 → 重测 → 观察新规律 → 修下一层。症状从「紫金必卡」变「随机卡」变「绿卡也卡」，正是逐层暴露的过程。
- 性能预算：动画路径上只允许 transform/opacity（合成器属性）；静态 filter/渐变只光栅化一次，可接受；`will-change` 慎用。

## 二、把浏览器生成的 CSS 导出为静态文件的坑

1. **agent-browser（或其他 CLI）eval 输出可能双重包裹引号**：JSON 字符串经 CLI 打印后可能多一层 `"`。文件写完后检查首字符——开头多一个 `"` 会让整个 CSS 被解析成未闭合字符串，**cssRules.length = 0**（这是判据：链接 200 但 0 条规则）。
2. **`style.textContent` 是 CSSOM 序列化形式**：选择器转义被加倍（`.md\:hidden` → `.md\\:hidden`），回灌源码后匹配不上。需把 `\\` 还原为 `\`（先确认文件中没有 `content:` 里的真字面反斜杠）。
3. **file:// 下 cssRules 拒绝访问**（opaque origin）：本地调试 CSS 解析必须起 `python -m http.server` 走同源 HTTP。
4. **级联顺序回归**：CDN 生成样式原本注入在自定义 CSS **之后**，靠「后加载者胜」压过同优先级冲突（典型：`.hidden` vs 自定义 `display:flex`）。静态 `<link>` 必须放在原注入位置之后，否则 `hidden` 类失效、遮罩层不隐藏——症状是「点不到被遮挡的元素，但遮挡区外的按钮正常」。

## 三、应用方法

1. 先问：卡顿与什么相关（稀有度/图片首现/DOM 变更/所有交互）？定位到某一层。
2. 优先修第 1、2 层（零成本预热、移除运行时编译），再动 CSS 特效写法。
3. 每次改动后做**真实指针点击**测试（JS `.click()` 会绕过遮挡层，掩盖遮罩类 bug），并用 computed style 断言（如 `display:none`）而非只看 DOM class。
