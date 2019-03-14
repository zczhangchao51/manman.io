title: vue 中优雅的使用 svg 图标

categories: doc

tags:

- vue
- svg
- 图标

date: 2018/09/09 12:00:00
excerpt_separator: <!--more-->

---

你从未见过的在 vue 使用 svg 的方式，简单又合理

<!--more-->

## 前言：

这不是给还不知道 svg 图标是什么同学看的，如果你还不知道 svg 可以做图标的话，建议你看这一篇[《未来必热：SVG Sprite 技术介绍》](https://www.zhangxinxu.com/wordpress/2014/07/introduce-svg-sprite-technology/)

## 现有方案

这里简单列举一些现有方案的优缺点：

### 1. [vue-svg-icon](https://github.com/cenkai88/vue-svg-icon)

运行时通过动态下载指定 svg，然后通过 xml 解析 svg 内容，然后提取主要属性赋值给组件来完成 svg 图标到组件的渲染

优点：

1. svg 代码动态下载，不会打包到组件内
2. 只需定义一个组件，使用时提供一个`name`属性即可

缺点：

1. 需要额外下载和解析 svg 时间
2. 需要引入一些没必要的解析 xml 的库
3. 方案不优雅

### 2. [vue-svg-loader](https://github.com/visualfanatic/vue-svg-loader)

通过 webpack 在编译时使用 vue-svg-loader 把.svg 后缀的文件编译为组件，然后在需要用到的地方注册并引入。

```js
<template>
  <div>
    <VueLogo />
    <SVGOLogo />
  </div>
</template>
<script>
import VueLogo from './public/vue.svg';
import SVGOLogo from './public/svgo.svg';

export default {
  name: 'Example',
  components: {
    VueLogo,
    SVGOLogo,
  },
};
</script>
```

优点：

1. 没有多余的运行时代码，在编译时就把 svg 打包进组件块中
2. 没有额外的网络请求的担忧

缺点：

1. 如果需要多个图标时就会很心累，需要注册很多个
2. 使用繁琐

### 3. [vue-svg-inline-loader](https://github.com/oliverfindl/vue-svg-inline-loader)

这是一个不错的方案，在 vue-loader 之后用 vue-svg-inline-loader 处理一遍.vue 文件，找到里面引用 svg 图标的<img>元素，然后把这些 svg 图标提取出来组成 svg-sprite,而且这一切都是自动的

例如下面模板列出的 img 图片

```js
<img
  svg-inline
  svg-sprite
  class="icon"
  src="./images/example.svg"
  alt="example"
/>
```

通过提取及编译，就会变成下面这样：

```js
<svg svg-inline svg-sprite class="icon" focusable="false" role="presentation" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
	<use xlink:href="#svg-sprite-md5hash" href="#svg-sprite-md5hash"></use>
</svg>
<!-- ... -->
<!-- will get injected right before root closing tag in Vue component -->
<svg xmlns="http://www.w3.org/2000/svg" style="display: none !important;">
	<symbol id="svg-sprite-md5hash" viewBox="...">
		<path d="..."></path>
	</symbol>
	<!-- ... -->
</svg>
```

优点：

1. 自动提取并组合起来，节省代码空间
2. 没有额外的网络请求的担忧
3. 使用简单

缺点：

1. 总觉得在 vue-loader 外层先处理.vue 文件会引发一些 bug(可能是心理原因)
2. svg-sprite 自身存在一些问题，use 不太好实现多色图标
3. 不好做动态化，经常在循环中才能确定使用的 svg 地址时这个方案就无能为力了
4. 所有图标都被打包到入口文件，增加体积

### 4. [svg-sprite-loader + webpack 范围加载](https://juejin.im/post/5bcfdad4e51d457a8254e9d6)

这也是 svg-sprite 相关的方案，不同于第 3 种的是该方案需要在 main.js 等入口位置提前声明好需要引入的 svg 图标，然后 webpack 会通过 svg-sprite-loader 把这些图标组合成 svg-sprite，剩下的就是准备一个组件来简化使用就好了

范围请求及自动合并

```js
import Vue from 'vue'
import SvgIcon from '@/components/SvgIcon' // svg组件

Vue.component('svg-icon', SvgIcon) //声明一个全局可用的简化svg-sprite使用的组件

const requireAll = requireContext => requireContext.keys().map(requireContext)
const req = require.context('./svg', false, /\.svg$/)
requireAll(req)
```

svg-icon 组件的简单实现

```js
<template functional>
  <svg :class="context.svgClass" aria-hidden="true">
    <use :xlink:href="context.name"/>
  </svg>
</template>

```

优点：

1. 自动提取并组合起来，节省代码空间
2. 没有额外的网络请求的担忧
3. 使用简单

缺点：

1. svg-sprite 自身存在一些问题，use 不太好实现多色图标
2. 所有图标都被打包到入口文件，增加体积

## 最终方案

综合各个方案的利弊后觉得，一个好的方案应该是这样的：

- 使用简单

- 应该是哪个组件的 svg 就只应该被打包到那个模块中

所以我找到了一个综合上面第 1 项和第 4 项的方案：

### 1.修改 vue.config.js

首先还是需要 vue-svg-loader 来处理.svg 文件

```js
module.exports = {
  chainWebpack: config => {
    const svgRule = config.module.rule('svg')

    svgRule.uses.clear()

    svgRule.use('vue-svg-loader').loader('vue-svg-loader')
  }
}
```

### 2.在 utils 公共方法里准备快捷的范围请求函数

```js
export const importSvg = function(resolve) {
  const cache = {}
  resolve.keys().forEach(key => {
    const component = resolve(key)
    component.name = key.slice(2).replace('.', '-')
    cache[key] = component
  })
  return Object.freeze(cache)
}
```

### 3.在单文件组件里使用

```js
<script>
import { importSvg } from '@/utils'
export default {
  data() {
    return {
      list: [
        {
          ame: './icon1.svg',
        }, {
          ame: './icon2.svg',
        }, {
          ame: './icon3.svg',
        }
      ],
      icons: importSvg(require.context('@/assets/svg/help', false, /\.svg$/))
    }
  }
}
</script>
```

这样就会把/assets/svg/help 里的.svg 文件都引进这个组件里了，并挂载在 data 上，其实也可以挂载在 methods 上，不过已经 Object.freeze 冻结过了，所以无所谓

### 4.在模板中使用 component 组件引用

```js
<template>
  <div>
    <components :is="icons[item.iconName]" class="icon"></components>
  </div>
</template>
```

大功告成！！！
