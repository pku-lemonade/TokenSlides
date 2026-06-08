#import "/lemonade.typ": *

#set text(lang: "zh")
#show: lemonade-theme.with(
    aspect-ratio: "16-9",
    box-compact: true,
    config-info(
        title: [vboxs layout check],
        author: [Lemonade],
        institution: [Theme QA],
    ),
)

= Box Layouts

== Single vbox

#vbox([大模型])[
    智谱
]

#vbox([Custom inset], title-inset: (left: 1em, right: 1em, top: 0.1em, bottom: 0.1em))[
    Title inset can be customized per box.
]

== Fill-height vboxs

#vboxs(
    ([大模型], [智谱]),
    ([超算中心], []),
    ([云服务提供商], [中国电信，阿里云]),
)

== Natural vboxs with widths

#vboxs(
    ([阶段一], [FPGA 仿真与编译器测试。]),
    ([阶段二], [芯片 V1 流片并完成 bring-up。]),
    ([阶段三], [围绕客户模型打磨软件栈与性能分析工具。]),
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
    标题应与正文处在同一水平行，正文仍保留左侧强调边。
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
