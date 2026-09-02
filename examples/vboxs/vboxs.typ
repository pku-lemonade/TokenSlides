#import "/lemonade.typ": *

#set text(lang: "zh")
#show: lemonade-theme.with(
    aspect-ratio: "16-9",
    box-compact: true,
    title: [vboxs layout check],
    author: [Lemonade],
    institution: [Theme QA],
)

= Box Layouts

== Single vbox

#vbox([大模型])[
    智谱
]

#vbox([Custom inset], title-inset: (left: 1em, right: 1em, top: 0.1em, bottom: 0.1em))[
    Title inset can be customized per box.
]

== Colored vbox family

#vboxs(
    vhbox([Highlight])[重点],
    vibox([Info])[信息],
    vebox([Error])[错误],
    vsbox([Success])[成功],
    vnbox([Neutral])[中性],
    vpbox([Purple])[扩展],
    title-size: 20pt,
    fill-height: false,
)

// A per-box size takes precedence over the row-level size above.
#vibox([Per-box title size], title-size: 24pt)[正文仍使用默认字号。]

== Fill-height vboxs with trailing content

#vboxs(
    vbox([大模型])[智谱],
    vbox([超算中心])[],
    vbox([云服务提供商])[中国电信，阿里云],
    after: callout[后续内容保留在拉伸行之外],
)

== Natural vboxs with widths

#vboxs(
    vbox([阶段一])[FPGA 仿真与编译器测试。],
    vbox([阶段二])[芯片 V1 流片并完成 bring-up。],
    vbox([阶段三])[围绕客户模型打磨软件栈与性能分析工具。],
    width: 70%,
    widths: (0.8fr, 1fr, 1.2fr),
    fill-height: false,
)

== Mixed box styles

#vboxs(
    vbox([客户])[智谱],
    ibox([关键风险])[供应商锁定、数据合规、交付排期],
    pbox(title: [合作机会])[联合优化推理成本],
    fill-height: false,
)

== Titled horizontal boxes

#hbox([Highlight])[
    标题应与正文处在同一水平行，正文改用中性边框。
]

#ibox(title: [Info])[
    命名参数标题也应使用同一套水平实心标题块。
]

== Fill-height mixed styles

#vboxs(
    vbox([默认])[
        顶部标题样式保持不变，内容仍然顶部对齐。
    ],
    ibox([信息框])[
        信息框在同一行内保留蓝色左边框。
    ],
    pbox([合作机会])[
        合作机会这一列保留紫色强调样式。
    ],
)

== Per-box body alignment

#vboxs(
    ibox([水平标题], body-align: left + horizon)[正文在等高盒子中垂直居中。],
    vpbox([顶部标题], body-align: left + horizon)[顶部标题盒子使用同一个正文对齐参数。],
)

= Stepped Rows

== `step: true`, with a trailing callout

#vboxs(
    vbox([阶段一])[FPGA 仿真与编译器测试。],
    vbox([阶段二])[芯片 V1 流片并完成 bring-up。],
    vbox([阶段三])[围绕客户模型打磨软件栈与性能分析工具。],
    after: callout[三个阶段揭示完毕后，结论才出现在自己的一页上],
    step: true,
)

== `step: 2`, offsetting a row behind a pause

一个 `#pause` 已经用掉了第一页，所以这一行从第二页开始。

#pause

#vboxs(
    vhbox([第二页])[本行第一列。],
    vibox([第三页])[本行第二列。],
    step: 2,
    fill-height: false,
)

== `step: (1, 1, 2)`, uneven groups in a stack

#vboxs(
    vbox([同时出现])[数组的前两项共用第一页。],
    vbox([同时出现])[所以这两栏一起揭示。],
    vbox([随后出现])[第三项留到第二页。],
    dir: ttb,
    step: (1, 1, 2),
    fill-height: false,
)

// Steps follow the order the items were WRITTEN, so an `rtl` row reveals from
// the right — the reverse of `widths`, which names tracks in drawing order.
== `step` with `dir: rtl` reveals right to left

#vboxs(
    vbox([先写的])[画在最右，第一页揭示。],
    vbox([后写的])[画在左侧，第二页揭示。],
    dir: rtl,
    step: true,
    fill-height: false,
)

= Nested Stacks

// `vstack` draws nothing of its own; it only lets one cell hold a second row.
// A stack divides its cell IN PROPORTION to what each item measures, so the two
// boxes below get shares matching their text, not one half each.
== A stack as one column of a filling row

#vboxs(
    ibox([单独一栏])[
        这一栏是一个普通行项，占满整行高度。
    ],
    vstack(
        vhbox([上])[右栏内部的第一项。],
        vsbox([下])[右栏内部的第二项，内容更长，因此分到更高的一格。],
    ),
    widths: (0.55fr, 0.45fr),
)

// `heights` names stacked tracks the way `widths` names side-by-side ones.
// `(1fr, 1fr)` is how a row asks for the even split that measuring would not
// have produced.
== `heights:` overrides the measured proportions

#vboxs(
    vstack(
        vhbox([2fr])[这一格拿到三分之二。],
        vsbox([1fr])[这一格拿到三分之一。],
        heights: (2fr, 1fr),
        fill-height: true,
    ),
    vstack(
        vhbox([1fr])[内容长短不再影响高度，],
        vsbox([1fr])[两格严格等分。],
        heights: (1fr, 1fr),
        fill-height: true,
    ),
)

// Both stacks below size their items by the same measured proportions; the only
// difference is whether those proportions are then scaled up to fill the cell.
// Filling is right for figures, which scale into whatever height they are given.
// A stack of boxes has nothing to scale, so filling only stretches the frames —
// that is what `fill-height: false` is for: every box at exactly its own height.
== `fill-height: false` for a stack of boxes

#vboxs(
    ibox([填满])[
        默认铺满整格：右侧两栏的高度比例相同，只差是否撑满。
    ],
    vstack(
        vhbox([上])[按比例放大后撑满。],
        vsbox([下])[内容更长，这一格也更高。],
        fill-height: true,
    ),
    vstack(
        vhbox([上])[各自保持自然高度。],
        vsbox([下])[比例不变，但不再撑满，框也不被拉伸。],
        fill-height: false,
    ),
)

== A stack keeps the row's `title-size`

// The row's title size crosses the stack boundary: `title-size` is threaded
// through the item spec, so nested boxes take it too.
#vboxs(
    vibox([外层])[标题字号来自这一行。],
    vstack(
        vebox([内层一])[嵌套后标题字号不变。],
        vpbox([内层二], title-size: 20pt)[单个盒子的 `title-size` 仍然优先。],
    ),
    title-size: 15pt,
    fill-height: false,
)

== `dir: ltr` inside a `dir: ttb` row

#vboxs(
    vstack(
        vhbox([左])[这一格里的两项并排。],
        vibox([右])[方向属于嵌套行，不是外层行。],
        dir: ltr,
    ),
    vnbox([整行])[外层是纵向堆叠，所以这一项自己占一整行。],
    dir: ttb,
    fill-height: false,
)

== A stack is one item of a stepped row

// Revealing belongs to the OUTER row: a stack is covered and uncovered whole,
// so one `step` index covers everything inside it.
#vboxs(
    vbox([第一页])[本行第一列。],
    vstack(
        vsbox([第二页])[整个 `vstack` 一起揭示。],
        vsbox([第二页])[内部各项没有自己的 `step`。],
    ),
    after: callout[堆叠仍然算作一项，所以结论落在第三页],
    step: true,
    fill-height: false,
)

== `after:` puts plain content inside a cell

// A row item is the only thing a cell takes, so a stack's `after:` is the way
// to get plain content (a callout, a line of prose) into one column.
//
// Turn a callout's `bleed` off inside a cell: bleed is measured in the SLIDE's
// side margins, so a bleeding callout in a narrow column spills that far past
// the column instead of widening by a share of it.
#vboxs(
    vstack(
        vhbox([证据一])[堆叠里的第一项。],
        vhbox([证据二])[堆叠里的第二项。],
        after: callout(config: (bleed: false))[小结留在这一栏内部],
    ),
    vnbox([另一栏])[对照列，与左栏等高。],
    fill-height: false,
)
