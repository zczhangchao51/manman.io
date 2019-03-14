title: 如何建设一个完整的文档体系

categories: doc

tags:

- vue
- docs
- vuepress

date: 2018/06/27 12:00:00
excerpt_separator: <!--more-->

---

涵盖开发，升级，非专业人员编写及绕过运维发版

<!--more-->

## 前言

来到新公司不久就接到一个需求，把原有 gitbook 编写的文档方案迁移到 docsify 中，正巧尤大大发布了 vuepress，一个优雅的文档方案，所以我力排众议推荐使用 vuepress，其实也是抱着可以学习的心态使用的。

## 面临的困难

这个事情当然不是迁移一下这么简单，而是有很多的难题摆在面前：

1. 这个事情希望做成一个示范项目，今后别的项目组需要写文档就按照这个模式进行

2. 之前 gitbook 写的文档都需要构建一下后丢到主项目里，然后更新还得发版

3. vuepress 的默认主题不太符合公司的形象，需要进行拓展

## 最终方案

经过很长时间的探索，终于找到了一个好的方案完美解决以上问题。

1. vuepress 构建出的资源使用七牛存放

2. 使用反向代理的方式将主站的某个次级目录的 html 文件指向七牛 html，并使用查询字符串的方式更新反向代理缓存

3. 使用 webpack 的 publishPath 达到将静态资源访问直接指向七牛 cdn

4. 使用 webpack 的 hash 机制达到不刷新七牛 cdn 也能确保静态资源不存在缓存不更新问题

5. 使用 script 脚本提供快捷选项让非开发人员也能方便完成编写文档，提交代码等操作

6. 维护一个公共主题，所有 UI 及功能都统一维护

7. 所有新的文档均从 文档项目 这个项目的 master 分支切出，这样后期所有功能升级及 bug 修复都能通过 merge master 得到，且又不影响当前项目文档内容

8. 绕过运维发版，不会受到 docker 等不确定因素的影响

## 关键库

文档生成器：[vuepress](https://github.com/vuejs/vuepress)

文档主题：[@KittenTeam/vuepress-theme-codemao_docs](https://github.com/KittenTeam/vuepress-theme-codemao_docs)

反向代理库： [@KittenTeam/koa-cache-proxy](https://github.com/KittenTeam/koa-cache-proxy)

七牛上传工具：qshell

## 使用步骤

例如我的项目域名 manman.io, 然后我想在 manman.io/docs 里部署一个帮助文档，但是我又不想把文档的内容揉到项目里

1 先从基础的脚手架项目 master 切出新的分支

2 配置一下 vuepress 的 base

```js
module.exports = {
  ...
  base: '/docs/',
  ...
}
```

3 publicPath 设置

vuepress 这里设置静态资源的 cdn 前缀，建议每次都把资源分前缀（prefix）放置，这样易于查看及管理，也避免不同文档间的影响，publicPath 由七牛 host + prefix 组成

```js
module.exports = {
...
chainWebpack: (config) => {
    if (process.env.NODE_ENV === 'production') {
      config.output.publicPath('https://www.xxx-cdn.com/docs/')
    }
  },
...
}
```

4 七牛上传配置
qshell 是七牛云的官方上传工具，请务必查看如何使用 qshell 再上传文件，下面列出一个简单的配置

```json
{
  "src_dir": "./dist",
  "bucket": "xxxxx", //空间
  "key_prefix": "docs/", //这里等同于上面的prefix
  "overwrite": true,
  "check_exists": true,
  "check_hash": true,
  "rescan_local": true
}
```

5 反向代理

重头戏来了，我们知道怎么上传文件到 cdn 了，剩下的就是如何把两个项目关联起来，我的结论是使用反向代理

在项目的启动文件里添加一个/docs 路径的反向代理，使用一个包含 hook 功能的 proxy 中间件

```js
const proxy = require('@KittenTeam/koa-cache-proxy')
let now = +new Date()
...
app.use(
  proxy({
    host: 'https://www.xxx-cdn.com',
    match: /^\/docs(\/)?/,
    map: function(path) {
      path = path.replace(/^\/docs(\/)?/, '/docs/')
      if (/\/$/.test(path)) {
        path = path + 'index.html'
      }
      return path + '?time=' + now //now的值可以理解为版本
    },
    suppressResponseHeaders: ['cache-control'],
    hooks: [ //定义一个get请求的hook, 触发该请求执行某个回调，用koa-router来完成hook功能也可以
      {
        path: '/docs/LfkFyA2UCcsn8NIr', //随便起的一个url
        handle(ctx) {
          now = +new Date()
        },
      },
    ],
 })
)
...
```

大功告成，现在每次写完文档只需要把文件上传到七牛，然后在主项目触发一下 hook 即可完成文档的更新

## 升级更新

由于统一从 master 分支切出，所以其他的子项目只需要 merge master 再升级依赖即可更新基础模板

## 主题更新及维护

理论上每个有兴趣的人都可以一起维护一个公共的文档主题

## 非开发人员使用指南

为了让非开发人员（产品、运营等）参与到文档的编写工作中，我们需要做一些工作

### 准备工作

1. 为非开发人员下载 vscode 及安装 git、node、git-bash（window）

2. 配置非开发人员的 git 用户名

3. 在非开发人员电脑上克隆代码

4. 简单培训如何写 markdown

5. 简单培训 git 基础流程

### 2 步骤

1. 命令行进入文档根目录

2. 拉取一次代码

3. 开启开发服务器编写文档

4. 编写完文档后提交代码(先拉取)

5. 建议非开发人员以日期作为 commit message

6. 开发人员拉取代码后发版

当然，我们可以准备一个 shell 脚本给他们

![命令行示例](https://images-cdn.shimo.im/TfV5egUOZpE9f4gD/image.png!thumbnail)

脚本大概长这样：

```sh
#!/bin/bash

# 错误后退出
set -e

# 调试
# set -x

echo "请输入数字1-9并回车选择要进行的操作"
echo

CURRENT_BRANCH=$(git symbolic-ref --short -q HEAD)

ASK=(
  安装/更新依赖包
  进入开发模式
  查看当前状态
  拉取代码
  推送代码
  查看版本历史
  构建及发版
  仅发版
  启动示例工程
)

select ACTION in ${ASK[@]}
  do
    echo
    if [[ $REPLY =~ ^[1-9]$ ]]; then
      case $REPLY in
        1 )
          npm i
        ;;
        2 )
          if [[ ! -d "./node_modules" ]]; then
            echo 你还没有安装依赖包，请先安装
          fi
          npm run dev
        ;;
        3 )
          git status -sb
        ;;
        4 )
          git pull origin $CURRENT_BRANCH
        ;;
        5 )
          git add .
          git commit -a
          git push origin $CURRENT_BRANCH
        ;;
        6 )
          git log --graph --pretty="%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset"
        ;;
        7 )
          npm run build
          qshell qupload 5 ./qnconfig.json
        ;;
        8 )
          qshell qupload 5 ./qnconfig.json
        ;;
        9 )
          npm run example
        ;;
      esac
    else
      echo 错误选项，请输入数字1-9进行选择
      echo
    fi
  done

```
