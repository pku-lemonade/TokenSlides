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
