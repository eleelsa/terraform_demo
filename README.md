# terraform_demo
for v0.12.24

[terraform_demo.pdf](https://github.com/eleelsa/terraform_demo/files/4680405/terraform_demo.pdf)

```
.
├── devel
│   ├── main.tf
│   └── scripts
│       ├── ConfigureRemotingForAnsible.ps1.tpl
│       ├── linux_common.sh.tpl
│       └── rh8.sh.tpl
├── module
│   ├── ec2
│   │   ├── key
│   │   │   ├── main.tf
│   │   │   └── output.tf
│   │   ├── main.tf
│   │   └── sg
│   │       ├── main.tf
│   │       └── output.tf
│   └── vpc
│       ├── main.tf
│       ├── output.tf
│       ├── route
│       │   └── main.tf
│       └── tg
│           ├── main.tf
│           └── output.tf
└── scripts
    └── ConfigureRemotingForAnsible_add_other.ps1
```
