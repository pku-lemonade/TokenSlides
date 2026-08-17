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
