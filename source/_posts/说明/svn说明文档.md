---
title: svn说明文档
date: 2018-3-1 19:50:00
comments: false
categories: 参考文档
description: SVN说明文档，我将我认为有用的部分汇总到这边了
tag: [SVN,说明文档]
---

[Subversion 版本控制 原文](http://svnbook.red-bean.com/nightly/zh/svn-book.html)

# Chapter 2. 基本用法

## 推荐的仓库布局

为了方便用户管理数据, Subversion 提供了很大的灵活性. Subversion 只是简单地对目录和文件进行版本控制, 不会给它们附上特殊的意义, 用户 完全可以按照自己的喜好来决定数据的布局. 不过, 这种灵活性有时也会带 来一些麻烦, 如果用户同时在 2 个或多个布局完全不同的仓库中浏览, 而这 些仓库的布局又没有规律, 用户往往会感到迷失, 不知身在何处.

为了避免这种问题, 我们推荐读者遵循传统的仓库布局 (这种布局 出现在很久以前, 在 Subversion 项目早期阶段就已经开始使用), 传统布局的 特点是, 仓库中的目录名可以向用户传达出与它们所存放的数据相关的信息.

* trunk 大多数项目都有一条公认的开发 “主线”, 或者叫作 主干 (trunk);
* branches 还有一 些 分支 (branches), 分 支是某一条开发线的分叉;
* tags 还有一些 标签 (tags), 标签是某一条开发线的稳定版快照.

我们首先建议 每一个项目在仓库中都一个公认的 项目根目录 (project root), 目录中只存放和该项目相关的 数据. 然后, 我们建议每一个项目根目录下都有一个表示开发主线的 trunk 子目录, 存放所有分支的 branches 子目录, 存放所有标签的 tags 子目录. 如果仓库只存放单个项目, 那么仓库的根目录也可以作为项目根目录.

这里有一些例子:

```
$ svn list file:///var/svn/single-project-repo
trunk/
branches/
tags/
$ svn list file:///var/svn/multi-project-repo
project-A/
project-B/
$ svn list file:///var/svn/multi-project-repo/project-A
trunk/
branches/
tags/
$
```


## 创建工作副本

大多数时候, 用户开始使用仓库是通过执行 检出 (checkout) 命令. 检出仓库中的目录将会在用户的 本地主机上创建一个该目录的工作副本. 除非特意指定, 否则这个副本将包 含仓库最新版本的数据:

```
$ svn checkout http://svn.example.com/svn/repo/trunk
A    trunk/README
A    trunk/INSTALL
A    trunk/src/main.c
A    trunk/src/header.h
…
Checked out revision 8810.
$
```

上面的例子检出的是主干目录, 但用户也可以轻易地检出更深层的子目录, 只需要在检出命令的参数中写上子目录对应的 URL 即可:

```
$ svn checkout http://svn.example.com/svn/repo/trunk/src
A    src/main.c
A    src/header.h
A    src/lib/helpers.c
…
Checked out revision 8810.
```

## 基本工作周期
Subversion 支持的特性与选项非常丰富, 但是能够在日常工作中用到的却很 少. 本节将介绍日常工作中最常用到的 Subversion 操作.

典型的工作周期就像:

* 更新工作副本. 这会用到命令 svn update.
* 修改.最常见的修改就是编辑已有文件的内容, 但有时还要添加, 删除, 复制和移动文件或目录 — 命令 svn add, svn delete, svn copy 和 svn move 负责 处理工作副本的结构性调整.
* 审核修改. 用命令 svn status 和 svn diff 查看工作副本发生了哪些变化.
* 修正错误. 人无完人, 在审核修改时用户可 能会发现某些修改是不正确的. 有时候修正错误最简单的方式是撤消所有的 修改, 重新开始. 命令 svn revert 可以把文件或目 录恢复到修改前的样子.
* 解决冲突 (合并其他人的修改). 当一个用户 正在修改文件时, 其他人可能已经把自己的修改提交到了服务器上. 为了防止 在提交修改时, 由于工作副本过旧导致提交失败, 用户需要把其他人的修改 更新到本地, 用到的命令是 svn update. 如果命令 的执行结果有冲突产生, 用户需要用命令 svn resolve 解决冲突.
* 发布 (提交) 修改. 命令 svn commit 把工作副本的修改提交到仓库中, 如果修改 被接受, 其他用户就可以看到这些修改.

### 更新工作副本

如果某个项目正在被多个工作副本修改, 用户就需要更新自己本地的 工作副本, 以获取其他人提交的修改. 这些修改可能来自团队中的其他开发 人员, 也可能是自己在其他地方提交的修改. Subversion 不允许用户向过时 的文件或目录提交修改, 所以在开始修改前, 最好保证本地工作副本的内容 是最新的.

命令 `svn update` 把仓库上的最新数据同步到本地 的工作副本:

```
$ svn update
Updating '.':
U    foo.c
U    bar.c
Updated to revision 2.
$
```


### 修改

现在用户可以开始工作, 修改工作副本里的资料. 工作副本支持的修改类型分 为两种: 文件修改 (file changes) 和 目录修改 (tree changes). 在修改文件时不需要告知 Subversion, 用户可以使用任意一种自己喜欢的工具来修改文件, 例如编辑 器, 字处理程序, 图形工具等. Subversion 可以自动检测到哪些文件发生了 变化, 处理二进制文件和处理文本文件一样简单高效. 目录修改涉及到目录结构 的变化, 例如添加和删除文件, 重命名文件和目录, 复制文件和目录. 目录修改 要使用 Subversion 的命令完成. 文件修改和目录修改只有在提交后才会更新 到仓库中.

如果把一个软链接提交到仓库中, Subversion 会自动加以识别. 如果在不支持软链接的 Windows 操作系统中检出工作副本, Subversion 就会 创建一个同名的普通文件, 文件内容是软链接所指向的对象的路径, 虽然该 文件不能当作一个软链接使用, 但 Windows 用户仍然可以编辑该文件.

下面是最常用到的 5 个改变目录结构的 Subversion 子命令:

* `svn add FOO` 这个命令把文件, 目录或软链接 FOO 添加 到需要进行版本控制的名单中, 在下一次提交时, FOO 就会正式添加到仓库里. 如果 FOO 是一个目录, 那么目录内的所有内容都会 被添加到仓库中. 如果只想添加 FOO 它自己, 就带上选项 `--depth=empty`.
* `svn delete FOO` 从工作副本中删除文件, 目录或符号链接 FOO, 在下一次提交时, FOO 就会从仓库中删除.
* `svn copy FOO BAR` 从 FOO 复制出一个 BAR, 并把 BAR 添加到 需要进行版本控制的名单中. BAR 被提交到仓库 后, Subversion 会记录它是由 FOO 复制得到的. 除非带上选项 --parents, 否则 svn copy 不会创建父目录.
* `svn move FOO BAR` 这条命令等价于 svn copy FOO BAR; svn delete FOO , 也就是从 FOO 复制出一个 BAR, 然后再删除 FOO. 除非带上选项 --parents, 否则 svn move 不会创建父目录.
* `svn mkdir FOO` 该命令等价于 mkdir FOO; svn add FOO, 也就是创建一个新目录 FOO, 并把它添加到仓库中.

执行基于 URL 的操作既有好处也有坏处, 比较明显的好处是速度快: 仅仅为了执行一个很简单的操作而检出工作副本, 未免也太麻烦了. 坏处 是用户一次只能执行一个或一种类型的操作. 使用工作副本最大的好处是 它可以作为修改的 “暂存区”, 在提交之前用户可以检查 修改是否正确. 暂存区的修改既可以简单, 也可以很复杂, 它们都 会被当作一个单独的修改提交到仓库中.

### 审核修改

工作副本修改完成后, 就要把它们都提交到仓库中, 不过在提交之前, 应该查看 一下自己到底修改了哪些东西. 通过检查修改, 用户可以写出更准确的 提交日志 (log message, 和修改一起存放到仓库中的一段文本, 该文本以人类可读的形式描述了本次 修改的相关信息). 在审核修改时, 用户可能会发现自己无意中修改了一个不相 关的文件, 因此在提交之前需要撤消它的修改. 用户可以使用命令 `svn status` 查看修改的整体概述, 用命令 `svn diff` 查看修改的细节.

#### 查看修改的整体概述

为了看到修改的整体概述, 使用命令 `svn status`, 它可能是用户最常用到的一个 Subversion 命令.

如果在工作副本的根目录不加任何参数地执行 svn status, Subversion 就会检查并报告所有 文件和目录的修改.

```
$ svn status
?       scratch.c
A       stuff/loot
A       stuff/loot/new.c
D       stuff/old.c
M       bar.c
$
```

在默认的输出模式下, svn status 先打印 7 列 字符, 然后是几个空白字符, 最后是文件或目录名. 第一列字符报告文件或 目录的状态, 其中最常的几种字符或状态是:

* **? item** 文件, 目录或符号链接 item 不在版本 控制的名单中.
* **A item** 文件, 目录或符号链接 item 是新增的, 在下一次提交时就会加入到仓库中.
* **C item** 文件 item 有未解决的冲突, 意思是说从 服务器收到的更新和该文件的本地修改有所重叠, Subversion 在处理 这些重叠的修改时发生了冲突. 用户必须解决掉冲突后才能向仓库 提交修改.
* **D item** 文件, 目录或符号链接 item 已被删除, 在下一次提交时就会从仓库中删除 item.
* **M item** 文件 item 的内容被修改.

如果给 svn status 传递一个路径名, 那么命 令只会输出和该路径相关的状态信息:

```
$ svn status stuff/fish.c
D       stuff/fish.c

```

svn status 支持选项 `--verbose (-v)`, 带上该选项后, 命令会输出当前目录中每一项的 状态, 即使是未被修改的项目:

```
$ svn status -v
M               44        23    sally     README
                44        30    sally     INSTALL
M               44        20    harry     bar.c
                44        18    ira       stuff
                44        35    harry     stuff/trout.c
D               44        19    ira       stuff/fish.c
                44        21    sally     stuff/things
A                0         ?     ?        stuff/things/bloo.h
                44        36    harry     stuff/things/gloo.c
```

这是 svn status 的 “长格式” (long form) 输出. 第一列字符的含义不变, 第二列显示该项在工作副本 中的版本号, 第三和第四列显示该项最后一次被修改的版本号和作者.

前面执行的几次 svn status 都不需要和仓库 通信 — 它们只是根据工作副本管理区里的数据和文件当前的内容 来报告各个文件的状态. 有时候用户可能想知道在上一次更新之后, 哪些 文件在仓库中又被更新了, 为此, 可以给 svn status 带上选项 `--show-updates (-u)`, 这样 Subversion 就会和仓库通信, 输出工作副本中已过时的项目:

```
$ svn status -u -v
M      *        44        23    sally     README
M               44        20    harry     bar.c
       *        44        35    harry     stuff/trout.c
D               44        19    ira       stuff/fish.c
A                0         ?     ?        stuff/things/bloo.h
Status against revision:   46
```
注意带有星号的那 2 行, 如果此时执行 svn update, 就会从仓库收到 README 和 trout.c 的更新. 除此之外我们还可以知道, 在本地被修改的文件当中, 至少有一个在仓库中 也被更新了 (文件 README), 所以用户必须在提交前把 仓库的更新同步到本地, 否则仓库将会拒绝针对已过时文件的提交, 关于这点我们会在后面介绍更多的细节.

除了我们介绍的例子, svn status 还可以显示更 丰富的信息, 关于 svn status 更详细的介绍, 查看 svn help status 的输出或阅读 svn Reference—Subversion Command-Line Client 的 svn status (stat, st)

#### 查看修改的细节

查看修改的另一个命令是 `svn diff`, 它会输出文件 内容的变化. 如果在工作副本的根目录不加任何参数地执行 svn diff, Subversion 就会输出工作副本中人类 可读的文件的变化. 文件的变化以 标准差异 (unified diff) 的格式输出, 这种格式把文件 内容的变化描述成 “块” (hunk) 或 “片断” (snippet), 其中每一行文本都加上一个单字符前缀: 空格表示该行没有 变化; 负号 (-) 表示该行被删除; 正号 (+) 表示该行是新增的. 在 svn diff 的语境中, 这些冠以正负号的行显示了修改 前的行和修改后的行分别是什么样子的.

这是一个执行 svn diff 的例子:

```
$ svn diff
Index: bar.c
===================================================================
--- bar.c	(revision 3)
+++ bar.c	(working copy)
@@ -1,7 +1,12 @@
+#include <sys/types.h>
+#include <sys/stat.h>
+#include <unistd.h>
+
+#include <stdio.h>

 int main(void) {
-  printf("Sixty-four slices of American Cheese...\n");
+  printf("Sixty-five slices of American Cheese...\n");
 return 0;
 }

Index: README
===================================================================
--- README	(revision 3)
+++ README	(working copy)
@@ -193,3 +193,4 @@
+Note to self:  pick up laundry.

Index: stuff/fish.c
===================================================================
--- stuff/fish.c	(revision 1)
+++ stuff/fish.c	(working copy)
-Welcome to the file known as 'fish'.
-Information on fish will be here soon.

Index: stuff/things/bloo.h
===================================================================
--- stuff/things/bloo.h	(revision 8)
+++ stuff/things/bloo.h	(working copy)
+Here is a new file to describe
+things about bloo.
```

`svn diff` 在比较了工作副本中的文件和基文本后 再输出它们之间的差异. 在命令的输出中, 新增的文件其每一行都被冠 以正号; 被删除的文件其每一行都被冠以负号. svn diff 的输出格式和程序 patch 以及 Subversion 1.7 引入的子命令 svn patch 兼容. 处理补丁的命令 (例如 patch 和 svn patch) 可以读取并应用 补丁文件 (patch files, 简称 “补丁”). 利用补丁, 用户就可以在不提交的情况下, 把工作副本的修改分享给其他 人, 创建补丁的方式是把 svn diff 的输出重定向到 补丁文件里:

```
$ svn diff > patchfile
$
```
Subversion 默认使用它自己内部的差异比较程序, 产生标准差异格式 的输出. 如果用户想要其他格式的差异输出, 就用选项 --diff-cmd 指定一个外部的差异比较程序, 如果需要 的话, 还可以用选项 --extensions 向差异比较程序 传递其他额外的参数. 例如, 用户想用 GNU 的程序 diff 对文件 foo.c 进行差异比较, 还要求 diff 在比较时忽略大小写, 按照上下文差异格式来 产生输出:

```
$ svn diff --diff-cmd /usr/bin/diff -x "-i" foo.c
…
$
```

### 修正错误

假设用户在查看 svn diff 的输出时发现针对某 一文件的修改都是错误的, 也许这个文件就不应该被修改, 也许重新开始 修改文件会更加容易. 为了撤消现在的修改, 用户可以再次编辑文件, 手动 地复原成原来的样子, 又或者是从其他地方找到一个原始文件, 把改错的 文件覆盖掉, 还可以用 svn patch --reverse-diff 或 patch -R 逆向应用补丁, 除此之外可能还有 其他办法.

幸运的是 Subversion 提供了一种简便的方法来撤消工作副本中的 修改, 用到的命令是 svn revert:

```
$ svn status README
M       README
$ svn revert README
Reverted 'README'
$ svn status README
$
```

在上面的例子里, Subversion 利用缓存在基文本中的内容, 把文件 回滚到修改前的原始状态. 需要注意的是, svn revert 会撤消 任何 一个未提交的修改, 例如用户可能不 想往仓库中添加新文件:

```
$ svn status new-file.txt
?       new-file.txt
$ svn add new-file.txt
A         new-file.txt
$ svn revert new-file.txt
Reverted 'new-file.txt'
$ svn status new-file.txt
?       new-file.txt
$
```
或者是用户错误地删除了一个本不该删除的文件:

```
$ svn status README
$ svn delete README
D         README
$ svn revert README
Reverted 'README'
$ svn status README
$
```
svn revert 提供了一个很好的补救机会, 否则的话, 用户就得花费大量的时间, 自己一点一点地手工撤消修改, 又或 者采用一个更麻烦的做法, 直接删除工作副本, 然后重新从服务器上检出一个 干净的工作副本.

### 解决冲突

我们已经看过 `svn status -u` 如何预测是否 有冲突, 但是解决冲突仍然需要由用户自己来完成. 冲突可以在用户把 仓库中的修改合并到本地工作副本的任何时候发生, 到目前为止用户已经 知道的命令中, svn update 就有可能产生冲突— 该命令的唯一功能就是把仓库中的更新合并到本地工作副本. 那么当发生冲突 时 Subversion 如何通知用户, 以及用户应该如何处理它们?

假设用户在执行 svn update 后看到了如下 输出:

```
$ svn update
Updating '.':
U    INSTALL
G    README
Conflict discovered in 'bar.c'.
Select: (p) postpone, (df) show diff, (e) edit file, (m) merge,
        (mc) my side of conflict, (tc) their side of conflict,
        (s) show all options:
```
不用担心左边有 U (Updated, 更新) 或 G (merGed, 合并) 的文件, 这表示 它们成功地吸收了来自仓库的更新. U 表示该文件不包含本地修改, 只是用仓库中的修改更新了文件内容. G 表示该文件含有本地修改, 但是这 些修改和来自仓库的修改没有重叠.

再下来几行就比较有趣了. 首先, Subversion 报告说在把仓库的修改 合并到文件 bar.c 时, 发现其中一些修改和本地未 提交的修改产生了冲突. 原因可能是其他人和用户都修改了同一行, 无论是 因为什么, Subversion 在发现冲突时会马上把文件置成冲突状态, 然后询问 用户他想怎么办. 用户可以从 Subversion 给出的几个选项中选择一个, 如果想看完整的选项列表, 就输入 s:

```
…
Select: (p) postpone, (df) show diff, (e) edit file, (m) merge,
        (mc) my side of conflict, (tc) their side of conflict,
        (s) show all options: s

  (e)  - change merged file in an editor  [edit]
  (df) - show all changes made to merged file
  (r)  - accept merged version of file

  (dc) - show all conflicts (ignoring merged version)
  (mc) - accept my version for all conflicts (same)  [mine-conflict]
  (tc) - accept their version for all conflicts (same)  [theirs-conflict]

  (mf) - accept my version of entire file (even non-conflicts)  [mine-full]
  (tf) - accept their version of entire file (same)  [theirs-full]

  (m)  - use internal merge tool to resolve conflict
  (l)  - launch external tool to resolve conflict  [launch]
  (p)  - mark the conflict to be resolved later  [postpone]
  (q)  - postpone all remaining conflicts
  (s)  - show this list (also 'h', '?')
Words in square brackets are the corresponding --accept option arguments.

Select: (p) postpone, (df) show diff, (e) edit file, (m) merge,
        (mc) my side of conflict, (tc) their side of conflict,
        (s) show all options:
```

先简单地介绍一下每一个选项.

* **(e) edit [edit]** 使用环境变量 EDITOR 定义的编辑器打开 发生冲突的文件.
* **(df) diff-full** 按照标准差异格式显示基础修订版和冲突的文件之间的差异.
* **(r) resolved** 编辑完成后, 告诉 svn 用户已经解决了冲突, 现在应该接受文件的当前内容.
* **(dc) display-conflict** 显示冲突的区域, 忽略合并成功的修改.
* **(mc) mine-conflict [mine-conflict]** 丢弃从服务器收到的, 与本地冲突的所有修改, 但是接受不会产生 冲突的修改.
* **(tc) theirs-conflict [theirs-conflict]** 丢弃与服务器产生冲突的所有本地修改, 但是保留不会产生冲突 的本地修改.
* **(mf) mine-full [mine-full]** 丢弃从服务器收到的该文件的所有修改, 但是保留该文件的 本地修改.
* **(tf) theirs-full [theirs-full]** 丢弃该文件的所有本地修改, 只使用从服务器收到的修改.
* **(m) merge** 打开一个内部文件合并工具来解决冲突, 该选项从 Subversion 1.8 开始支持.
* **(l) launch** 打开一个外部程序来解决冲突, 在第一次使用该选项之前需要完成 一些准备工作.
* **(p) postpone [postpone]** 让文件停留在冲突状态, 在更新完成后再解决冲突.
* **(s) show all** 显示所有的, 可以用在交互式的冲突解决中的命令.

我们将对以上命令进行更为详细的说明, 说明中将按照功能对命令进行 分组.

#### 交互式地查看冲突差异
在决定如何交互地解决冲突之前, 有必要看一下冲突的内容, 其中有两 个命令可以帮到我们. 第一个是 df:

```
…
Select: (p) postpone, (df) show diff, (e) edit file, (m) merge,
        (mc) my side of conflict, (tc) their side of conflict,
        (s) show all options: df
--- .svn/text-base/sandwich.txt.svn-base      Tue Dec 11 21:33:57 2007
+++ .svn/tmp/tempfile.32.tmp     Tue Dec 11 21:34:33 2007
@@ -1 +1,5 @@
-Just buy a sandwich.
+<<<<<<< .mine
+Go pick up a cheesesteak.
+=======
+Bring me a taco!
+>>>>>>> .r32
…
```

差异内容的第一行显示了工作副本之前的内容 (版本号 BASE), 下一行是用户的修改, 最后一行是从服务器 收到的修改 (通常 是版本号 HEAD).

第二个命令和第一个比较类似, 但是 dc 只会显示冲突区域, 而不是文件的所有修改. 另外, 该命令显示冲突区域 的格式也稍有不同, 这种格式允许用户更方便地比较文件在三种状态下的 内容: 原始状态; 带有用户的本地修改, 忽略服务器的冲突修改; 带有服 务器的修改, 忽略用户的本地修改.

审核完这些命令提供的信息之后, 用户就可以采取下一步动作.

#### 交互式地解决冲突差异

交互式地解决冲突的主要方法是使用一个内部文件合并工具, 该工具 询问用户如何处理每一个冲突修改, 而且允许用户有选择地合并和编辑修改. 除此之外还有其他几种方式用于交互式地解决冲突—其中两种允许用 户使用外部编辑器, 有选择地合并和编辑修改, 另外几种允许用户简单地选择 文件版本. 内部合并工具集合了所有解决冲突的方式.

看完引起冲突的修改后, 接下来就要解决这些冲突. 我们要介绍的第 一个命令是 m (merge), 从 Subversion 1.8 开 始支持, 该命令允许用户从众多选项中选择一个来解决冲突:
```
Select: (p) postpone, (df) show diff, (e) edit file, (m) merge,
        (mc) my side of conflict, (tc) their side of conflict,
        (s) show all options: m
Merging 'Makefile'.
Conflicting section found during merge:
(1) their version (at line 24)                  |(2) your version (at line 24)
------------------------------------------------+------------------------------------------------
top_builddir = /bar                             |top_builddir = /foo
------------------------------------------------+------------------------------------------------
Select: (1) use their version, (2) use your version,
        (12) their version first, then yours,
        (21) your version first, then theirs,
        (e1) edit their version and use the result,
        (e2) edit your version and use the result,
        (eb) edit both versions and use the result,
        (p) postpone this conflicting section leaving conflict markers,
        (a) abort file merge and return to main menu:
```

从上面可以看到, 使用内部文件合并工具时, 用户可以循环遍历文件中 的每一个冲突区域, 对每一个冲突区域用户都可以选择一个不同的选项, 或者 推迟解决该冲突.

如果用户想用一个外部编辑器来选择本地修改的某些组合, 此时可用 用命令 e (edit) 来手动地编辑带有冲突标记的 文件, 该命令会打开一个文本编辑器 (参考 the section called “Using External Editors”). 文件编辑完毕后, 如果用户感到满意, 就要用命令 r (resolved) 告诉 Subversion 文件的冲突已经解决了.

不管别人怎么说, 使用文本编辑器编辑文件来解决冲突是一种比较低 级的方法 (见 the section called “手动地解决冲突”), 因此, Subversion 提供了一个命令 l (launch) 来打开 精美的图形化合并工具 (见 the section called “External merge”).

还有两个稍微折衷一点的选项, 命令 mc (mine-conflict) 和 tc (theirs-conflict) 分别告诉 Subversion 选择用户的本地修改或从服务器收到的修改作为冲突 获胜的一方. 但是和 “mine-full” 以及 “theirs-full” 不同的是, 这两个命令会保留不产生冲突的 本地修改和从服务器收到的修改.

最后, 如果用户决定只想使用本地修改, 或者是只使用从服务器收到 的修改, 可以分别选择 mf (mine-full) 与 tf (theirs-full).

#### 推迟解决冲突

这节的标题看起来好像是在讲如何避免夫妻之间爆发冲突, 可实际上 本节还是在介绍和 Subversion 相关的内容. 如果用户在更新时遇到了冲 突, 但是还没有准备好立即解决, 这时可以选择 p 来推迟解决. 如果用户早就准备好不想交互式地解决冲突, 可以给 svn update 增加一个参数 --non-interactive, 此时发生冲突的文件会被自动 标记为 C.

从 Subversion 1.8 开始, 内部的文件合并工具允许用户推迟解决 某些特定的冲突, 但仍然可以解决其他冲突. 于是, 用户可以以冲突 区域为单位 (而不仅仅是以文件为单位) 来决定哪些冲突可以推迟解决.

C (“Conflicted”) 表示来自服务器的修改和用户的本地修改有所重叠, 用户在更新完成后必须 手动加以选择. 如果用户推迟解决冲突, svn 通常 会从三个方面帮助用户解决冲突:

* 如果在更新过程中产生了冲突, Subversion 就会为含有冲突的 文件打印一个字符 C, 并记住 该文件处于冲突状态.
* 如果 Subversion 认为文件是支持合并的, 它就会把 冲突标记 (conflict markers)—一段给冲突划分 边界的特殊文本—插入到文本中来显式地指出重叠区域 (Subversion 使用属性 svn:mime-type 来判断 一个文件是否支持基于行的合并, 见 the section called “文件内容类型”).
* 对每一个产生冲突的文件, Subversion 都会在工作副本中生成 三个额外的文件, 这些文件不在版本控制的名单中:
* * **filename.mine** 该文件的内容和用户执行更新操作前的文件内容相同, 它 包含了当时所有的本地修改 (如果 Subversion 认为该文件不 支持合并就不会创建 .mine).
* * **filename.rOLDREV** 该文件的内容和版本号 BASE 对应 的文件内容相同, 也就是在执行更新操作前工作副本中未修改 的版本, OLDREV 是基础版本号.
* * **filename.rNEWREV** 该文件的内容和从服务器收到的版本相同, NEWREV 等于更新到的版本号 (如果没有额外指定的话, 就是 HEAD).

例如, Sally 修改了文件 sandwich.txt, 但 是还没有提交. 同时, Harry 提交了同一文件的修改. 在提交前 Sally 执行了更新操作, 结果产生了冲突, 她选择推迟解决冲突:

```
$ svn update
Updating '.':
Conflict discovered in 'sandwich.txt'.
Select: (p) postpone, (df) show diff, (e) edit file, (m) merge,
        (mc) my side of conflict, (tc) their side of conflict,
        (s) show all options: p
C    sandwich.txt
Updated to revision 2.
Summary of conflicts:
  Text conflicts: 1
$ ls -1
sandwich.txt
sandwich.txt.mine
sandwich.txt.r1
sandwich.txt.r2
```

此时, 直到这三个临时文件被删除之前, Subversion 不会允许 Sally 提交 sandwich.txt:

```
$ svn commit -m "Add a few more things"
svn: E155015: Commit failed (details follow):
svn: E155015: Aborting commit: '/home/sally/svn-work/sandwich.txt' remains in conflict
```

如果用户选择推迟解决冲突, 只有在冲突解决之后, Subversion 才 会重新允许用户提交修改, 其中要用到的命令是 svn resolve. 该命令接受一个 --accept 选项, 它指明了用户想要如何解决冲突. 在 Subversion 1.8 以前, --accept 是 svn resolve 的必填选项, 但是现在它是可选的. 如果不带 --accept 地执行 svn resolve, Subversion 就会进入交互式地冲突 解决步骤, 这部分内容我们已经在上一节— the section called “交互式地解决冲突差异”—介绍过了. 下面我们会介绍如何使用选项 --accept.

选项 --accept 指示 Subversion 使用预先定义 好的几种方法之一来解决冲突. 如果用户想要使用上一次检出时版本,就 写成 --accept=base; 如果用户只想保留自己的修改, 就写成 --accept=mine-full; 如果用户只想保留从 服务器收到的更新, 就写成 --accept=theirs-full. 除了刚才介绍的几个, 还有其他一些选项值, 参考 svn Reference—Subversion Command-Line Client 的 --accept ACTION.

如果用户想要自己选择哪些修改进入最终版本, 那就自己手动编辑 文件, 修改冲突区域 (带有冲突标记的区域), 然后使用选项 --accept=working 告诉 Subversion 把文件的 当前内容作为冲突解决后的状态.

svn resolve 删除三个临时文件, 将用户指定的 文件版本作为冲突解决后的最终版. 命令执行成功后 Subversion 不再认为 文件处于冲突状态:

```
$ svn resolve --accept working sandwich.txt
Resolved conflicted state of 'sandwich.txt'
```

#### 手动地解决冲突

第一次尝试手动解决冲突会让不少人感到紧张, 但只要多练几次, 就会像 骑自行车一样简单.

这里有一个例子. 由于沟通上的误会, 你和你的同事, Sally, 同时修改 了 sandwich.txt, Sally 先提交了修改, 结果当你 更新工作副本时发生了冲突, 现在你需要手动编辑文件来解决冲突. 首先先 看一下发生冲突后的文件内容:

```
$ cat sandwich.txt
Top piece of bread
Mayonnaise
Lettuce
Tomato
Provolone
<<<<<<< .mine
Salami
Mortadella
Prosciutto
=======
Sauerkraut
Grilled Chicken
>>>>>>> .r2
Creole Mustard
Bottom piece of bread
```

分别由小于号, 等号和大于号组成的行是冲突标记, 它们不是冲突数据 的一部分, 用户通常只需要确保在提交前把它们都删除掉即可. 前两个标记之 间的文本是用户的本地修改.

```
<<<<<<< .mine
Salami
Mortadella
Prosciutto
=======
```

后两个标记之间的内容是 Sally 提交的修改:

```
=======
Sauerkraut
Grilled Chicken
>>>>>>> .r2
```

通常情况下你不能直接删除冲突标记和 Sally 的修改— 否则的话当她收到三明治时就会感到一头雾水, 此时你应该向她说明意大 利熟食店不出售泡洋白菜丝. 假设 sandwich.txt 修改完毕后的内容是:

```
Top piece of bread
Mayonnaise
Lettuce
Tomato
Provolone
Salami
Mortadella
Prosciutto
Creole Mustard
Bottom piece of bread
```
使用命令 svn resolve 移除文件的冲突状态后, 接下来就可以提交修改了:

```
$ svn resolve --accept working sandwich.txt
Resolved conflicted state of 'sandwich.txt'
$ svn commit -m "Go ahead and use my sandwich, discarding Sally's edits."
```

通常情况下, 如果用户还没有编辑好文件就不要用 svn resolve 告诉 Subversion 你已经解决好了 冲突, 因为临时文件一旦被删除, 即使文件中还含有冲突标记, Subversion 依然会允许用户提交修改.

如果用户在编辑含有冲突的文件时感到困惑, 应该看一下 Subversion 创建的那三个临时文件, 甚至可以用第三方的交互式文件合并工具来查看 它们.

#### 只使用从服务器收到的更新

如果在更新时产生了冲突, 而你想要完全丢弃自己的修改, 就执行 svn resolve --accept theirs-full CONFLICTED-PATH , 此时 Subversion 就会丢弃用户的本地修改, 并 删除临时文件:

```
$ svn update
Updating '.':
Conflict discovered in 'sandwich.txt'.
Select: (p) postpone, (df) show diff, (e) edit file, (m) merge,
        (mc) my side of conflict, (tc) their side of conflict,
        (s) show all options: p
C    sandwich.txt
Updated to revision 2.
Summary of conflicts:
  Text conflicts: 1
$ ls sandwich.*
sandwich.txt  sandwich.txt.mine  sandwich.txt.r2  sandwich.txt.r1
$ svn resolve --accept theirs-full sandwich.txt
Resolved conflicted state of 'sandwich.txt'
$
```

#### 使用 `svn revert`

如果用户决定丢弃当前的所有修改 (无论是在冲突后, 还是在任何时候), 就 用 svn revert:

```
$ svn revert sandwich.txt
Reverted 'sandwich.txt'
$ ls sandwich.*
sandwich.txt
$
```

注意, 含有冲突的文件被回滚后不需要再对它使用 svn resolve.


### 提交修改

终于, 所有的编辑都完成了, 从服务收到的更新也已合并完成, 现在你 已经准备好向仓库提交修改.

`svn commit` 把本地的所有修改发往仓库. 提交时 用户需要输入一段日志来描述本次修改, 日志被附加到新的版本号上. 如果 日志比较简短, 可以用选项 --message (-m) 直接在命令行上输入日志:

```
$ svn commit -m "Corrected number of cheese slices."
Sending        sandwich.txt
Transmitting file data .
Committed revision 3.
```

如果用户已经事先把日志写到了某个文本文件中, 希望 Subversion 在 提交时直接从该文件中读取日志, 这可以通过选项 --file (-F) 实现:

```
$ svn commit -F logmsg
Sending        sandwich.txt
Transmitting file data .
Committed revision 4.
```
如果用户在提交时没有指定选项 --message (-m) 或 --file (-F), Subversion 就会自动打开用户指定的编辑器 (见 the section called “General configuration” 的 editor-cmd) 来编写日志.


仓库不知道也不关心用户的提交是否有意义, 它只能确保没有人趁你不 注意时修改了同一文件. 如果确实有人这么做了, 整个提交就会失败, 并打印 一条错误消息说其中某些文件过时了:

```
$ svn commit -m "Add another rule"
Sending        rules.txt
Transmitting file data .
svn: E155011: Commit failed (details follow):
svn: E155011: File '/home/sally/svn-work/sandwich.txt' is out of date
…
```

(错误消息的具体内容取决于网络协议和服务器, 但是基本内容都是类似 的.)

此时用户需要执行 svn update, 解决可能 的冲突, 然后再次尝试提交.

本节介绍的内容覆盖了 Subversion 的基本工作周期. 为了方便用户 使用仓库和工作副本, Subversion 还提供了很多特性, 但是在大部分情况下, Subversion 的日常使用只会用到我们目前所介绍的这些命令. 下面我们还将 会介绍几个较常用到的命令.


## 检查历史
Subversion 仓库就像一台时间机器, 它记录了用户提交的每一次修改, 允许用户查看文件和目录以前的版本, 以及它们的元数据. 只要一个命令, 用户就可以检出仓库在以前任意一个时间点或版本号的版本 (或者回滚工作 副本的版本号). 不过, 有时候用户可能只是想看一下过去的历史, 而不是想真正地回到过去.

下面几个命令提供了检索历史数据的功能:

* **svn diff** 从行的级别上查看修改的内容
* **svn log** 和版本号绑定的日志消息, 及其日期, 作者, 以及受影响的文件 路径.
* **svn cat** 根据给定的版本号, 输出文件在该版本下的内容.
* **svn annotate** 根据给定的版本号, 查看该版本下的文件的每一行的最后一 次修改信息.
* **svn list** 根据给定的版本号, 列出仓库在该版本下的文件与目录清单.

### 查看历史修订的细节

我们已经介绍过 svn diff—按照标准差异格式 显示文件的变化, 前文我们是用它显示工作副本的本地修改.

实际上, svn diff 有三种用法:

* 查看本地修改
* 比较工作副本和仓库
* 比较仓库的版本号

#### 查看本地修改

如果不带选项地执行 svn diff, 命令就会拿文件的当前内容和存放在 .svn 中的原始 文件作对比:

```
$ svn diff
Index: rules.txt
===================================================================
--- rules.txt	(revision 3)
+++ rules.txt	(working copy)
@@ -1,4 +1,5 @@
 Be kind to others
 Freedom = Responsibility
 Everything in moderation
-Chew with your mouth open
+Chew with your mouth closed
+Listen when others are speaking
$
```

#### 比较工作副本和仓库

如果带上选项 --revision (-r), 命令就把工作副本和仓库中指定的版本号作对比:

```
$ svn diff -r 3 rules.txt
Index: rules.txt
===================================================================
--- rules.txt	(revision 3)
+++ rules.txt	(working copy)
@@ -1,4 +1,5 @@
 Be kind to others
 Freedom = Responsibility
 Everything in moderation
-Chew with your mouth open
+Chew with your mouth closed
+Listen when others are speaking
$
```

#### 比较仓库的版本号

如果用选项 --revision (-r) 传递了一对用冒号隔开的版本号, 命令就会比较这两个版本号的差异.

```
$ svn diff -r 2:3 rules.txt
Index: rules.txt
===================================================================
--- rules.txt	(revision 2)
+++ rules.txt	(revision 3)
@@ -1,4 +1,4 @@
 Be kind to others
-Freedom = Chocolate Ice Cream
+Freedom = Responsibility
 Everything in moderation
 Chew with your mouth open
$
```

如果要比较某个版本号与前一个版本号, 比较方便的做法是用选项 --change (-c):

```
$ svn diff -c 3 rules.txt
Index: rules.txt
===================================================================
--- rules.txt	(revision 2)
+++ rules.txt	(revision 3)
@@ -1,4 +1,4 @@
 Be kind to others
-Freedom = Chocolate Ice Cream
+Freedom = Responsibility
 Everything in moderation
 Chew with your mouth open
$
```
最后, 即使本地机器上没有工作副本, svn diff 也可以比较仓库的版本号, 方法是在命令行中指定 URL:

```
$ svn diff -c 5 http://svn.example.com/repos/example/trunk/text/rules.txt
…
$
```

### 生成历史修改列表

为了查看某个文件或目录的历史修改信息, 使用命令 svn log, 它显示的信息包括提交修改的作者, 版本号, 时间和日期, 以及日志消息 (如果有的话):

```
$ svn log
------------------------------------------------------------------------
r3 | sally | 2008-05-15 23:09:28 -0500 (Thu, 15 May 2008) | 1 line

Added include lines and corrected # of cheese slices.
------------------------------------------------------------------------
r2 | harry | 2008-05-14 18:43:15 -0500 (Wed, 14 May 2008) | 1 line

Added main() methods.
------------------------------------------------------------------------
r1 | sally | 2008-05-10 19:50:31 -0500 (Sat, 10 May 2008) | 1 line

Initial import
------------------------------------------------------------------------
```

注意, svn log 默认按照时间逆序来打印消息, 如果用户只想查看某段范围内的日志, 或者是单个版本号的日志, 又或者是想 改变打印顺序, 就带上选项 --revision (-r):

Table 2.1. 常见的日志请求

|命令|描述|
|----|----|
|svn log -r 5:19|按照时间顺序打印从版本号 5 到 19 的日志|
|svn log -r 19:5|按照时间逆序打印从版本号 5 到 19 的日志|
|svn log -r 8	|显示版本号 8 的日志|

如果用户想在日志消息中看到更多的细节, 就带上选项 --verbose (-v). 因为 Subversion 允许用户移动和复制文件或目录, 所以如果能在日志中看到文件路径的变化 就方便多了. 带上选项 --verbose (-r) 后, svn log 的输出中就会包含被修改的文件路径:

```
$ svn log -r 8 -v
------------------------------------------------------------------------
r8 | sally | 2008-05-21 13:19:25 -0500 (Wed, 21 May 2008) | 1 line
Changed paths:
   M /trunk/code/foo.c
   M /trunk/code/bar.h
   A /trunk/code/doc/README

Frozzled the sub-space winch.

------------------------------------------------------------------------
```

svn log 还支持选项 --quiet (-q), 它会阻止打印日志消息主体, 如果和 --verbose (-v) 一起使用, 那么 svn log 只会打印被修改的文件路径.

从 Subversion 1.7 开始, 用户还可以让 svn log 产生标准差异格式的输出, 就像 svn diff. 如果给 svn log 加上选项 --diff, 用户就可以在行的级别上看到本次修订的具体修改内容, 于是, 用户可以同 时从高层的语义修改和底层的基于行的变化来查看文件的修改历史.

从 Subversion 1.8 开始, svn log 支持选项 --search 和 --search-and. 这两个 选项允许用户指定搜索模式字符串, 从而过滤 svn log 的输出: 只有当版本号的作者, 日期, 日志消息或被修改的文件路径与搜索 模式匹配时, 才会输出该日志.

### 浏览仓库

利用 svn cat 和 svn list, 用户可以查看任意一个版本号下的文件和目录, 而无须修改工作副本, 实际上, 在使用这两个命令时甚至都不需要工作副本.

#### 显示文件的内容

如果用户只想查看文件旧版本的内容, 可以用 svn cat:

```
$ svn cat -r 2 rules.txt
Be kind to others
Freedom = Chocolate Ice Cream
Everything in moderation
Chew with your mouth open
$
```
还可以把输出重定向到一个文件中:

```
$ svn cat -r 2 rules.txt > rules.txt.v2
$
```

#### 显示每一行的修改属性

和 `svn cat` 比较类似的命令是 `svn annotate 有点类似`, 但是 svn annotate 的输出更丰富—除了文件的内容外, 还会输出每一行 最后一次被修改时的作者, 版本号及其日期 (可选).

如果参数是工作副本中的文件, svn annotate 会根据文件的当前内容输出每一行的属性:

```
$ svn annotate rules.txt
     1      harry Be kind to others
     3      sally Freedom = Responsibility
     1      harry Everything in moderation
     -          - Chew with your mouth closed
     -          - Listen when others are speaking
```

在上面的例子里, 某些行的属性没有打印出来, 原因是这几行在工作 副本中被修改了. 利用这个特点, 我们也可以通过 svn annotate 判断出文件的哪些行被修改了. 用户可以用版本号关键词 BASE (见 the section called “版本号关键字”) 查看文件的未修改版本的输出:

```
$ svn annotate rules.txt@BASE
     1      harry Be kind to others
     3      sally Freedom = Responsibility
     1      harry Everything in moderation
     1      harry Chew with your mouth open
```

选项 --verbose (-v) 使得 svn annotate 在输出中增加每一行的版本号的 提交日期 (这会显著增加输出内容的宽度, 所以我们不在这里展示添加 了选项 --verbose 后的运行效果).

和 svn cat 一样, svn annotate 也能针对文件的旧版本进行操作, 这个功能有时候会很有 帮助—如果用户已经找到了文件中某一行的最后一次修改的版本号, 他可能还想知道在此之前是谁最后一次修改了这一行:

```
$ svn blame rules.txt -r 2
     1      harry Be kind to others
     1      harry Freedom = Chocolate Ice Cream
     1      harry Everything in moderation
     1      harry Chew with your mouth open
```

和 svn cat 不同的是, svn annotate 的正常运行要求文件必须是人类可读的, 以行为单位的文本 文件, 如果 Subversion 认为文件不是人类可读的 (根据文件的 svn:mime-type 属性—见 the section called “文件内容类型”), svn annotate 就输出一条错误消息:

```
$ svn annotate images/logo.png
Skipping binary file (use --force to treat as text): 'images/logo.png'
$
```
就像错误消息中提示的那样, 用户可以通过增加选项 --force 来禁止 Subversion 去检查文件是否是人类 可读的. 如果用户强制要求 svn annotate 去读取 非人类可读的文件, 命令就会输出一堆混乱的信息:

```
$ svn annotate images/logo.png --force
     6      harry \211PNG
     6      harry ^Z
     6      harry
     7      harry \274\361\MI\300\365\353^X\300…
```

和许多获取信息的命令一样, `svn annotate` 也接受仓库的 URL 作为参数, 这样即使没有工作副本, 用户也可以照常 执行命令.

#### 列出被版本控制的文件

命令 `svn list` 可以列出仓库目录中的文件, 而 不用把它们下载到本地:

```
$ svn list http://svn.example.com/repo/project
README
branches/
tags/
trunk/
```
如果想得到更详细的信息, 添加选项 --verbose (-v):

```
$ svn list -v http://svn.example.com/repo/project
  23351 sally                 Feb 05 13:26 ./
  20620 harry            1084 Jul 13  2006 README
  23339 harry                 Feb 04 01:40 branches/
  23198 harry                 Jan 23 17:17 tags/
  23351 sally                 Feb 05 13:26 trunk/
```
从左到右分别表示文件或目录最后一次被修改时的版本号, 作者, 文件大小 (仅针对文件), 日期以及文件或目录的名字.

### 获取老的仓库快照

用户可以用带有选项 --revision (-r) 的 svn update 命令, 把整个工作副本回退到旧版本: [7]

```
# Make the current directory look like it did in r1729.
$ svn update -r 1729
Updating '.':
…
$
```


如果用户想以较老的快照为基础创建一个新的工作副本, 只要稍微修改 一下 svn checkout 的命令行即可; 对于 svn update, 可以给它添加一个选项 --revision (-r). 由于 the section called “挂勾版本号与实施版本号” 介绍的原因, 用户可能想 把目标版本号作为 Subversion 扩展 URL 语法的一部分.

```
# Checkout the trunk from r1729.
$ svn checkout http://svn.example.com/svn/repo/trunk@1729 trunk-1729
…
# Checkout the current trunk as it looked in r1729.
$ svn checkout http://svn.example.com/svn/repo/trunk -r 1729 trunk-1729
…
$
```

如果用户想构建一个发布版, 其中包含了所有的被版本控制的文件和 目录, 命令 svn export 可以完成这项工作. svn export 在本地创建一份仓库的完整或部分副本, 但是没有 .svn 目录. 命令的基本语法和 svn checkout 相同:

```
# Export the trunk from the latest revision.
$ svn export http://svn.example.com/svn/repo/trunk trunk-export
…
# Export the trunk from r1729.
$ svn export http://svn.example.com/svn/repo/trunk@1729 trunk-1729
…
# Export the current trunk as it looked in r1729.
$ svn export http://svn.example.com/svn/repo/trunk -r 1729 trunk-1729
…
$
```

## 有时候你需要的只是清理一下

既然我们已经讲到了使用 Subversion 时经常碰到的日常工作, 现在将介绍 一些和工作副本相关的管理性任务.

### 删除工作副本

服务端的 Subversion 不会跟踪工作副本的状态或存在情况, 所以工作 副本不会影响服务器的工作负载. 同样, 删除工作副本时也不需要告诉服务 器.

如果用户下次可能还要用到工作副本, 那么在下次使用之前, 直接把工作 副本留在磁盘上也不会产生什么问题, 不过在开始使用之前, 记得用 svn update 更新一下工作副本.

然而, 如果用户已经确定自己以后不会再用到工作副本, 为了节省磁盘 空间, 你也可以用操作系统提供的删除命令把工作副本删除掉. 但是在删除 之前我们建议执行一下 svn status, 然后查看带有前缀 ? 的列表中是否有重要的文件.

### 从中断中恢复

当 Subversion 修改工作副本时—修改文件或文件的管理状态— 它会尽量保证操作能够安全地执行. 在修改工作副本之前, Subversion 把 它的意向操作记在一个私有的 “待完成列表” (to-do list) 中, 然后开始执行操作, 在执行过程中 Subversion 会去获取工作副本中相 关部分的锁, 这可以避免其他客户端在工作副本处于中间状态时对它进行 访问, 最后, Subversion 释放锁并清理待完成列表. 从结构上来看, 它有点 像日志文件系统. 如果 Subversion 的一个操作被中断了 (例如进程被杀死或 机器崩溃), 待完成列表将保留在磁盘上, 这就允许 Subversion 后面可以再 打开列表, 做完未完成的工作, 把工作副本恢复到一致的状态.

上面介绍的正是 svn cleanup 的功能: svn cleanup 在工作副本中搜索未完成的工作, 操作完成 时移除工作副本的锁. 如果 Subversion 告诉你工作副本中的某些部分是被 “锁住” 的, 执行 svn cleanup 就可以解决 该问题. svn status 也会显示工作副本的加锁状态, 被加锁的路径其左边有一字符 L:

```
$ svn status
  L     somedir
M       somedir/foo.c
$ svn cleanup
$ svn status
M       somedir/foo.c
```

不要把工作副本的管理锁和用户创建的锁相混淆, 后者是为了实现 并发版本控制的 加锁-修改-解锁 模型, 见 “锁” 的多种涵义.

## 处理结构性冲突

到目前为止我们只在文件内容的级别上讨论冲突, 如果你和你的同事在 同一文件上的修改相互重叠, 那么 Subversion 就会要求你在合并了这些修改 之后才能提交. [8]

如果其他人把你正在编辑的文件移动到其他地方或删除了, 那这时候又会发生 什么事? 发生这种事的原因可能是同事之间沟通不及时, 一个人认为文件应该 被删除, 而另一个人还想接着修改该文件, 也可能是你的同事想重新规划目录 布局. 如果你正在编辑的文件已经移动到了其他位置, 那么提交的修改可能会 应用到移动后的文件中. 这种冲突的级别是在目录树结构上, 而不是在文件的 内容上, 称为 目录冲突 (tree conflicts).

和文件内容的冲突一样, 只有在目录冲突解决之后才能向仓库提交修改.

### 目录冲突示例

假设有一个软件项目的代码目录结构如下所示:

```
$ svn list -Rv svn://svn.example.com/trunk/
     13 harry                 Sep 06 10:34 ./
     13 harry              27 Sep 06 10:34 COPYING
     13 harry              41 Sep 06 10:32 Makefile
     13 harry              53 Sep 06 10:34 README
     13 harry                 Sep 06 10:32 code/
     13 harry              54 Sep 06 10:32 code/bar.c
     13 harry             130 Sep 06 10:32 code/foo.c
$
```
后来, 在版本号 14, 你的同事 Harry 把 bar.c 重命名为 baz.c, 但是你并不知情. 此时你正忙于 编写另外一套修改, 其中就牵涉到 bar.c:

```
$ svn diff
Index: code/foo.c
===================================================================
--- code/foo.c	(revision 13)
+++ code/foo.c	(working copy)
@@ -3,5 +3,5 @@
 int main(int argc, char *argv[])
 {
     printf("I don't like being moved around!\n%s", bar());
-    return 0;
+    return 1;
 }
Index: code/bar.c
===================================================================
--- code/bar.c	(revision 13)
+++ code/bar.c	(working copy)
@@ -1,4 +1,4 @@
 const char *bar(void)
 {
-    return "Me neither!\n";
+    return "Well, I do like being moved around!\n";
 }
$
```
提交失败时你开始意识到有人已经修改了 bar.c:

```
$ svn commit -m "Small fixes"
Sending        code/bar.c
Transmitting file data .
svn: E155011: Commit failed (details follow):
svn: E155011: File '/home/svn/project/code/bar.c' is out of date
svn: E160013: File not found: transaction '14-e', path '/code/bar.c'
$
```
此时应该执行 svn update, 命令不仅把 Harry 的修改同步到本地工作副本, 还产生了一个目录冲突:

```
$ svn update
Updating '.':
   C code/bar.c
A    code/baz.c
U    Makefile
Updated to revision 14.
Summary of conflicts:
  Tree conflicts: 1
$
```
在上面的例子中, svn update 在第四列放置一个 大写字母 C 表示该条目有冲突. svn status 可以显示冲突的其他细节:

```
$ svn status
M       code/foo.c
A  +  C code/bar.c
      >   local edit, incoming delete upon update
Summary of conflicts:
  Tree conflicts: 1
$
```
注意 bar.c 如何又被自动地添加到工作副本中, 如果用户想保留 bar.c, 就不需要再额外执行一次 svn add.

由于 Subversion 是用一个复制操作和一个删除操作实现移动, 而且在 更新时很难将这两个操作联系在一起, 所以 Subversion 的警告信息只是说 在本地被修改的文件已经在仓库中被删除了, 这个删除可能是移动操作的一 部分, 也可能就是一次单纯的删除操作. 准确地判断仓库在语义上发生了什 么变化显得尤为重要—只有这样才能让自己的修改适应项目的整体 轨迹. 为了弄清楚冲突发生的原因, 你可以阅读日志, 和同事沟通, 在行的 级别上查看修改等.

在这个例子里, Harry 的提交日志提供了所需要的信息.

```
$ svn log -r14 ^/trunk
------------------------------------------------------------------------
r14 | harry | 2011-09-06 10:38:17 -0400 (Tue, 06 Sep 2011) | 1 line
Changed paths:
   M /Makefile
   D /code/bar.c
   A /code/baz.c (from /code/bar.c:13)

Rename bar.c to baz.c, and adjust Makefile accordingly.
------------------------------------------------------------------------
$
```
svn info 显示了冲突条目的 URL. 左边 (left) 的 URL 显示了 冲突的本地端来源, 右边 (right) 的 URL 显示了冲突的服务器端来源, 这些 URL 指出了我们应该从哪个版本号开始搜索导致冲突的修改.

```
$ svn info code/bar.c
Path: code/bar.c
Name: bar.c
URL: http://svn.example.com/svn/repo/trunk/code/bar.c
…
Tree conflict: local edit, incoming delete upon update
  Source  left: (file) ^/trunk/code/bar.c@4
  Source right: (none) ^/trunk/code/bar.c@5

$
```
bar.c 已经成为目录冲突的受害者, 在冲突解决 之前无法提交:

```
$ svn commit -m "Small fixes"
svn: E155015: Commit failed (details follow):
svn: E155015: Aborting commit: '/home/svn/project/code/bar.c' remains in confl
ict
$
```
为了解决这个冲突, 用户要么同意, 要么不同意 Harry 提交的重命名 修改.

如果用户同意重命名, 那么 bar.c 就成了多余的 了, 你可能想要删除 bar.c 并把目录冲突标记为已 解决, 但是请等一下, 文件上还有你的修改! 在删除 bar.c 之前你必须决定它上面的修改是否需要应用到 其他地方, 比如重命名后的文件 baz.c. 不妨假设你 的修改需要 “跟随重命名” (follow the move), 但是 Subversion 还没有聪明到能够替你完成这件工作[9], 所以你必须手动地迁移修改.

在我们例子里, 你完全可以手动地再修改一次 baz.c—毕竟只修改了一行, 但是这种做法只适用 于修改很少的情况, 我们再介绍一种更具有通用性的方法. 先用 svn diff 创建一个补丁文件, 然后修改补丁文件的头 部信息, 使其指向重命名后的文件, 最后再应用修改后的补丁.

```
$ svn diff code/bar.c > PATCHFILE
$ cat PATCHFILE
Index: code/bar.c
===================================================================
--- code/bar.c	(revision 14)
+++ code/bar.c	(working copy)
@@ -1,4 +1,4 @@
 const char *bar(void)
 {
-    return "Me neither!\n";
+    return "Well, I do like being moved around!\n";
 }
$ ### Edit PATCHFILE to refer to code/baz.c instead of code/bar.c
$ cat PATCHFILE
Index: code/baz.c
===================================================================
--- code/baz.c	(revision 14)
+++ code/baz.c	(working copy)
@@ -1,4 +1,4 @@
 const char *bar(void)
 {
-    return "Me neither!\n";
+    return "Well, I do like being moved around!\n";
 }
$ svn patch PATCHFILE
U         code/baz.c
$
```
现在 bar.c 上的修改已经成功地转移到了 baz.c 上, 用户现在可以删除 bar.c 并告诉 Subversion 把工作副本的当前内容 作为冲突解决的结果.

```
$ svn delete --force code/bar.c
D         code/bar.c
$ svn resolve --accept=working code/bar.c
Resolved conflicted state of 'code/bar.c'
$ svn status
M       code/foo.c
M       code/baz.c
$ svn diff
Index: code/foo.c
===================================================================
--- code/foo.c  (revision 14)
+++ code/foo.c  (working copy)
@@ -3,5 +3,5 @@
 int main(int argc, char *argv[])
 {
     printf("I don't like being moved around!\n%s", bar());
-    return 0;
+    return 1;
 }
Index: code/baz.c
===================================================================
--- code/baz.c  (revision 14)
+++ code/baz.c  (working copy)
@@ -1,4 +1,4 @@
 const char *bar(void)
 {
-    return "Me neither!\n";
+    return "Well, I do like being moved around!\n";
 }
$
```
但是如果你不同意重命名, 那又该如何? 如果用户已经确定 baz.c 上的修改已经进行了保存或者可以丢弃, 那也可以 直接删除 baz.c (别忘了撤消 Harry 对 Makefile 的修改). 因为 bar.c 已经准备好添加到仓库中, 所以接下来只需 要把冲突标记为已解决即可:

```
$ svn delete --force code/baz.c
D         code/baz.c
$ svn resolve --accept=working code/bar.c
Resolved conflicted state of 'code/bar.c'
$ svn status
M       code/foo.c
A  +    code/bar.c
D       code/baz.c
M       Makefile
$ svn diff
Index: code/foo.c
===================================================================
--- code/foo.c	(revision 14)
+++ code/foo.c	(working copy)
@@ -3,5 +3,5 @@
 int main(int argc, char *argv[])
 {
     printf("I don't like being moved around!\n%s", bar());
-    return 0;
+    return 1;
 }
Index: code/bar.c
===================================================================
--- code/bar.c	(revision 14)
+++ code/bar.c	(working copy)
@@ -1,4 +1,4 @@
 const char *bar(void)
 {
-    return "Me neither!\n";
+    return "Well, I do like being moved around!\n";
 }
Index: code/baz.c
===================================================================
--- code/baz.c	(revision 14)
+++ code/baz.c	(working copy)
@@ -1,4 +0,0 @@
-const char *bar(void)
-{
-    return "Me neither!\n";
-}
Index: Makefile
===================================================================
--- Makefile	(revision 14)
+++ Makefile	(working copy)
@@ -1,2 +1,2 @@
 foo:
-	$(CC) -o $@ code/foo.c code/baz.c
+	$(CC) -o $@ code/foo.c code/bar.c
```
恭喜, 你已经解决了你的第一个目录冲突! 现在你可以提交修改, 并告诉 Harry 由于他的修改, 你做了很多额外的工作.

## 小结

本章我们介绍了 Subversion 客户端的大部分命令, 剩下的命令中比较 重要的几个主要用于分支与合并 (见 Chapter 4, 分支与合并), 以及属性 (见 the section called “属性”). 然而, 你可能想 快速浏览一下 svn Reference—Subversion Command-Line Client, 看看 Subversion 到底提供 了多少个命令, 这些命令又如何帮助你提高工作效率.

# Chapter 3. 高级主题

如果读者是从头开始, 一章一章地阅读本书, 那么你应该拥有了足够的知识 去使用 Subversion 客户端工具完成最常见的版本控制操作. 你已经知道了如何 从 Subversion 仓库检出工作副本, 如何用 svn commit 和 svn update 提交和接收修改, 甚至运行 svn status 已经成为了你的下意识动作. 总之, 你已经准备 好在一个典型的应用环境中使用 Subversion.

但是 Subversion 远远不止 “常见的版本控制操作”, 除了 和中央仓库沟通文件和目录的变化外, 它还具备很多功能.

本章将要介绍的 Subversion 特性, 用户在自己的日常工作中可能不会用到, 但是却很重要. 本章假设读者已经熟悉了 Subversion 基本的文件与目录的版本 控制功能, 如果读者还不了解这方面的内容, 先阅读 Chapter 1, 基本概念 和 Chapter 2, 基本用法 这两章. 一旦 读者消耗了本章内容, 你将会成为一位强大的 Subversion 用户.

### 版本号指示器

我们已经在 the section called “版本号” 说过, Subversion 的版本号非常直观—随着提交的不断增多, 表示版本号的整数 也不断增大, 但是用不了多久, 用户就再也记不清每个版本号包含了哪些修改. 幸运的是, Subversion 的典型工作流程不太经常要求用户提供版本号, 对于 那些确实需要版本号的操作而言, 用户可以从提交日志中看到所需的版本号, 或者 使用在特定语境下可以表示特定版本号的关键字.

但是在少数情况下, 用户必须精确及时地指出版本号, 但手上却没有合适的参数. 所以除了用整数指定版本号, svn 还支持另外两种指定版本 号的形式: 版本号关键字 (revision keywords) 和版本号日期.

### 版本号关键字

Subversion 支持理解的版本号关键字有很多个, 可以用这些关键字替换 选项 --revision (-r) 后面的整数, 这些关键字会被 Subversion 解释成特定的版本号:

* **HEAD** 仓库中最近的 (或最年轻的) 版本号.
* **BASE** 工作副本中的某一项目的版本号, 如果该项在本地被修改了, 则该 版本号引用的是修改前的项目.
* **COMMITTED** 等于或早于 BASE 并且离它最近的一个版本号, 在该版本号中项目被修改了.
* **PREV** 项目最后一次被修改时的版本号的前一个版本号, 从技术上讲它 就是 COMMITTED-1.

从它们的描述可以看出, PREV, BASE 和 COMMITTED 只能引用工作 副本中的路径, 而 HEAD 既可以引用工作副本中的路径, 也可以引用仓库的 URL.

下面是一些版本号关键字的使用示例:

```
$ svn diff -r PREV:COMMITTED foo.c
# shows the last change committed to foo.c

$ svn log -r HEAD
# shows log message for the latest repository commit

$ svn diff -r HEAD
# compares your working copy (with all of its local changes) to the
# latest version of that tree in the repository

$ svn diff -r BASE:HEAD foo.c
# compares the unmodified version of foo.c with the latest version of
# foo.c in the repository

$ svn log -r BASE:HEAD
# shows all commit logs for the current versioned directory since you
# last updated

$ svn update -r PREV foo.c
# rewinds the last change on foo.c, decreasing foo.c's working revision

$ svn diff -r BASE:14 foo.c
# compares the unmodified version of foo.c with the way foo.c looked
# in revision 14
```

### 版本号日期

版本号没有透露出一丝一毫与版本控制系统外部世界相关的信息, 但是有 时候你需要把真实世界的时间与版本控制历史的时间联系起来. 为此, 选项 --revision (-r) 也接受日期形式的 参数, 日期用一对花括号 ({ 和 }) 包裹起来, Subversion 接受标准的 ISO-8601 格式的日期与时间, 以及其他 一些形式, 下面是一些例子.

```
$ svn update -r {2006-02-17}
$ svn update -r {15:30}
$ svn update -r {15:30:00.200000}
$ svn update -r {"2006-02-17 15:30"}
$ svn update -r {"2006-02-17 15:30 +0230"}
$ svn update -r {2006-02-17T15:30}
$ svn update -r {2006-02-17T15:30Z}
$ svn update -r {2006-02-17T15:30-04:00}
$ svn update -r {20060217T1530}
$ svn update -r {20060217T1530Z}
$ svn update -r {20060217T1530-0500}
…
```

如果用户指定了一个日期, Subversion 就把该日期解析成最近的版本号, 然后再针对该版本号进行操作:

```
$ svn log -r {2006-11-28}
------------------------------------------------------------------------
r12 | ira | 2006-11-27 12:31:51 -0600 (Mon, 27 Nov 2006) | 6 lines
```

还可以指定一段日期范围, 此时 Subversion 会找到这段时间内的所有 版本号, 包括开始日期和结束日期:

```
$ svn log -r {2006-11-20}:{2006-11-29}
```

## 挂勾版本号与实施版本号

我们经常在自己的系统中对文件和目录进行复制, 移动, 重命名和替换, 但是版本控制系统不能按照相同的方式操作它所管理的文件与目录. Subversion 的文件管理非常灵活, 但是这种灵活性也意味着在仓库的生命周期中, 一个版本 控制对象可能会有多个路径, 而一个路径在不同时间可能表示完全不同的版本控制 对象, 当用户同这些路径与对象交互时会产生一定的复杂度.

如果对象的版本历史里包含了 "地址上的变化", Subversion 自己就会注意 到这点. 比如说用户要求查看上周被重命名的一个文件的版本历史, Subversion 会提供全部的相关日志—重命名发生时版本号, 再加上重命名前与重命名后 的相关版本号. 所以说在大部分情况下, 用户都不需要考虑对象的地址变化可能 带来的影响, 但是在少数情况下, Subversion 需要你的帮助来消除歧义.

最简单的一种场景是一个文件或目录从仓库中被删除后, 又有一个同名的 文件或目录被添加到仓库中, 被删除的对象和新增的对象之间毫无关系, 只是 碰巧路径相同, 假设都是 /trunk/object, 那么向 Subversion 询问 /trunk/object 的历史是表示什么 意思? 是在问当前对象的历史, 还是那个被删除的对象的历史? 或者是在问 该路径上存在过的 所有 对象的操作历史? 为了得到 自己想要的信息, Subversion 需要一些提示.

由于移动操作, 对象的历史变得更加复杂. 比如说你有一个目录叫作 concept, 它包含了几个初期的软件项目. 慢慢地, 软件开始成型, 你开始考虑为项目取一个名字[10]. 假设你要取的软件名字是 Frabnaggilywort, 把目录重命名成 软件的名字是很合理的操作, 于是 concept 被重命名 为 frabnaggilywort. 项目接着进行, Frabnaggilywort 发布了 1.0 版, 很多用户都下载了并在日常工作中使用它.

故事听起来还不错, 但是还没结束. 企业家的脑子里经常会有新想法出现, 于是你又创建了一个新目录 concept, 循环再次开始. 实际上, 在几年内循环会重复进行多次, 每一次都以创建 concept 开始, 如果想法逐渐地明朗起来, concept 很可能会被重新命名; 如果想法被否定了, concept 就会被删除. 更有甚者, 用户还有可能把 concept 改名一段时间后, 又改回到 concept.

在这种场景下, 指挥 Subversion 操作这些重复使用的路径就好像在指挥 一个摩托车手, 从芝加哥的 West Suburbs 向东行驶到 Roosevelt Road, 再向 左驶入 Main Street. 在短短的 20 分钟里, 你会穿过 Wheaton, Glen Ellyn 和 Lombard 的 “Main Street”, 但它们并非是同一个地方, 我们的 摩托车手—也就是 Subversion—需要更多的细节才能把事情做对.

幸运的是, Subversion 允许用户精确地指定他想去的是哪一个 Main Street, 其中 用到的特性是 挂勾版本号 (peg revision), 它的目的是确定一条唯一的历史线. 因为在任意一个给定的时刻 (或者说给定的版本号) 一条路径上至多只能有一个版 本控制对象, 所以说结合使用路径与挂勾版本号就可以明确地识别一条特定的 历史线. 挂勾版本号使用 at 语法 (at syntax) 在 Subversion 的命令行客户端工具上 指定, 之所以叫作 “at 语法” 是因为指定版本号的方式是在路径 的末尾加上符号 @, 然后再写上版本号.

但是本书多次提到的 --revision (-r) 到底 是什么? 这个版本号或版本号集合叫作 实施版本号 (operative revision) 或 实施版本号范围 (operative revision range ). 一旦用路径和挂勾版本号确定一条特定的历史线, Subversion 就 对实施版本号执行用户请求的操作. 用芝加哥的道路进行类比, 如果我们要去 Wheaton 的 606 N. Main Street[11], 可以把 “Main Street” 看成路径, 把 “Wheaton” 看成挂勾 版本号, 这两项信息确定了一条唯一的路径, 避免我们走弯路. 现在我们把 “606 N.” 作为实施版本号, 最终我们得到了一个精确的目的地.

> 挂勾版本号算法
>
> 提供给客户端命令行工具的路径和版本号参数如果可能含有歧义, Subversion 就会运行挂勾版本号算法来消除歧义, 下面是一个说明用的 示例:
>
> `$ svn command -r OPERATIVE-REV item@PEG-REV`
> 如果 OPERATIVE-REV 比 PEG-REV 老, 算法的执行过程是:
>
> 定位由版本号 PEG-REV 识别的 item, 有且仅有一个对象.
>
> 反向追踪对象的历史 (还要考虑重命名操作带来的影响), 直到版本号 OPERATIVE-REV 里的祖先.
>
> 对祖先执行用户所请求的操作, 无论当时这个祖先位于何处, 叫什么 名字.
>
但是如果 OPERATIVE-REV 比 PEG-REV 年轻 的话又会如何? 这会给定位 OPERATIVE-REV 中的路径的理论 问题增加一些复杂度, 因为在 PEG-REV 和 OPERATIVE-REV 之间, 路径的历史可能会多 次发生分叉 (由于复制操作). 不仅如此, Subversion 不会为了高效地正向 追踪对象的历史而记录足够多的信息. 所以在这种情况下的算法会有一些差别:
>
> 定位由版本号 OPERATIVE-REV 识别的 item, 有且仅有一个对象.
>
> 反向追踪对象的历史 (还要考虑重命名操作带来的影响), 直到版本号 PEG-REV 里的祖先.
>
> 检查对象在 PEG-REV 和 OPERATIVE-REV 中的位置 (路径) 是否相同, 如果是, 说明至少这两个位置是直接相关的, 那就在 OPERATIVE-REV 的位置上执行用户所请求的操作. 否则的话相关性无法 建立, 输出错误信息, 表示无法找到可用的路径 (也许某一天 Subversion 对这种情况会处理得更加灵活与优雅).
>
> 注意, 即使用户没有显式地给出挂勾版本号或实施版本号, 它们仍然存在. 为了方便用户, 工作副本里的项目的挂勾版本号默认是 BASE , 仓库 URL 默认是 HEAD. 如果没有显式 指定实施版本号, 则默认与挂勾版本号相同.

比如说用户在很久以前就创建了仓库, 在版本号 1 添加了第一个目录 concept, 用户后来在目录里放了一个介绍概念的文件 IDEA. 几次提交后, 项目的代码逐渐成型, 在版本号 20 用户把 concept 重命名为 frabnaggilywort . 在版本号 27, 用户又有了一个新主意, 所以在项目根目录下又 创建了目录 concept, 里面也放了一个描述概念的文件 IDEA. 然后又过了 5 年, 期间提交了几千次修改.

几年后, 用户想知道文件 IDEA 在版本号 1 中是什么 样子, 但是 Subversion 需要知道用户是在询问 当前 文件 在版本号 1 时的内容, 还是在问版本号 1 中文件 concept/IDEA 的内容. 当然这两个问题的答案是不一样的, 利用挂勾版本号, 用户 就可以向 Subversion 说明他想问的是哪一个问题. 为了确定当前的 IDEA 在版本号 1 时的内容, 用户执行了:

```
$ svn cat -r 1 concept/IDEA
svn: E195012: Unable to find repository location for 'concept/IDEA' in revision 1
```

当然, 在这个例子里, 当前的文件 IDEA 在版本号 1 时并不存在, 于是 Subversion 报了一个错误. 上面的命令实际上是以下显式 指定持勾版本号命令的简写形式:

```
$ svn cat -r 1 concept/IDEA@BASE
svn: E195012: Unable to find repository location for 'concept/IDEA' in revision 1
```

命令的执行结果是预料之中的.

敏锐的读者可能想知道是否是挂勾版本号的语法导致了问题, 因为工作副本 路径或 URL 本身可能就带有符号 @, 毕竟 svn 怎么知道 news@11 是表示一个目录的普通名字, 还是表示 “news 的版本号 11”? 谢天谢地, svn 总是当成后一种情况, 方法是在路径的末尾添加一 个 @ 符号, 例如 news@11@. svn 只关心参数中的最后一个 @, 即使省略了 @ 后面的版本号也是合法的. 这个方法也适用 于以 @ 结尾的路径—你可以用 filename@@ 表示一个名为 filename@ 的文件.

再考虑另一个问题—在版本号 1 中, 占用路径 concept/IDEA 的文件的内容是什么? 我们可以用一个 带有显式挂勾版本号的命令来回答这个问题.

```
$ svn cat concept/IDEA@1
The idea behind this project is to come up with a piece of software
that can frab a naggily wort.  Frabbing naggily worts is tricky
business, and doing it incorrectly can have serious ramifications, so
we need to employ over-the-top input validation and data verification
mechanisms.
```
注意在上面的命令中我们并没有提供实施版本号, 这是因为如果没有指定 实施版本号, Subversion 默认使用挂勾版本号作为实施版本号.

命令的执行结果看来是正确的, 输出的文本甚至提到了 “frab a naggily wort”, 所以它描述的软件应该就是现在的 Frabnaggilywort, 实际上我们还可以通过组合显式的挂勾版本号和显式的实施版本号来验证这一点. 我们已经知道在 HEAD 里, 项目 Frabnaggilywort 位于目录 frabnaggilywort, 于是我们希望看到 HEAD 的 frabnaggilywort/IDEA 在版本号 1 中 的内容.
```
$ svn cat -r 1 frabnaggilywort/IDEA@HEAD
The idea behind this project is to come up with a piece of software
that can frab a naggily wort.  Frabbing naggily worts is tricky
business, and doing it incorrectly can have serious ramifications, so
we need to employ over-the-top input validation and data verification
mechanisms.
```
挂勾版本号和实施版本号也不需要如此琐碎, 举例来说, frabnaggilywort 已经从 HEAD 删除, 但是我们知道它在版本号 20 时还是存在的, 而且我们想知道其中存放的 IDEA 在版本号 4 和版本号 10 之间的差异, 可以使用挂 勾版本号 20, 结合上文件 IDEA 的版本号 20 的 URL, 然后使用 4 和 10 作为实施版本号范围.

```
$ svn diff -r 4:10 http://svn.red-bean.com/projects/frabnaggilywort/IDEA@20
Index: frabnaggilywort/IDEA
===================================================================
--- frabnaggilywort/IDEA	(revision 4)
+++ frabnaggilywort/IDEA	(revision 10)
@@ -1,5 +1,5 @@
-The idea behind this project is to come up with a piece of software
-that can frab a naggily wort.  Frabbing naggily worts is tricky
-business, and doing it incorrectly can have serious ramifications, so
-we need to employ over-the-top input validation and data verification
-mechanisms.
+The idea behind this project is to come up with a piece of
+client-server software that can remotely frab a naggily wort.
+Frabbing naggily worts is tricky business, and doing it incorrectly
+can have serious ramifications, so we need to employ over-the-top
+input validation and data verification mechanisms.
```
幸运的是, 大多数人都不会碰到哪些复杂的情况, 但是如果遇到了, 记住 挂勾版本号可以帮助 Subversion 清除歧义.

## 属性

我们已经详细地描述了 Subversion 如何存放和检索存放在仓库中的不同 版本的文件和目录, 介绍这些最基本的功能用了一整章的篇幅. 如果 Subversion 对版本控制的支持就到此为止, 从版本控制的角度来看它的功能已经很完整了.

但 Subversion 并没有停下脚步.

作为目录和文件版本控制的补充, Subversion 提供了为每一个文件和目录添加, 修 改和删除版本化元数据的接口. 我们把这些元数据称为 属性 (properties), 属性可看作是一张两列的表格, 附加到 工作副本的每条项目上, 表格把属性的名字映射到任意值. 一般来说, 属性的名字 和值可以是任意的, 唯一的要求是属性名只能使用 ASCII 字符. 属性最好的地方 是它们也是被版本控制的对象, 就像文件的内容那样, 用户可以修改, 提交和撤销 属性的修改. 用户执行提交和更新操作时, 属性的修改也会被发送和接收— 用户的工作流程不会因为属性的加入而发生变化.

除了文件和目录, 属性还可以出现在其他地方, 每一个版本号都是一个实体, 可以在它上面附加任意的属性, 唯一的要求是属性名只能使用 ASCII 字符. 同文件和目录的属性相比, 最大的不同是版本号的属性不会被版本控制, 也就是 说如果版本号的属性被删除或修改了, Subversion 没有能力恢复以前的值.

关于属性的使用, Subversion 并没有很特别的策略, 唯一的要求是用户不 要使用以 svn: 开始的属性名, 这是保留给 Subversion 使用的名字空间, Subversion 使用的属性包括版本化的和未版本化的. 文件和 目录上特定的版本化属性具有特殊的意义或效果, 或提供了版本号的一些信息. 在提交时, 特定的版本号属性被自动地附加到版本号上, 属性包含了与版本号 有关的信息. 大多数属性会在谈到相关的主题时再介绍, Subversion 的预定义 属性的完整列表见 the section called “Subversion 的保留属性”.

本节将检验 svn—不仅是对 Subversion 用户, 也对 Subversion 自身—对属性的支持. 读者将会学到与属性相关的 svn 子命令, 以及属性如何影响用户的工作检验.

### 为什么需要属性?

Subversion 使用属性存放和文件, 目录, 版本号相关的额外信息, 读者 可能也会发现属性的类似用法. 你会发现, 如果在数据附近能有个地方保存 自定义元数据将会是一项非常有用的特性.

假设你想要设计一个网站, 其中存放了很多数字照片, 在显示时会给照片 加上标题和日期. 因为你的照片经常发生变化, 所以你希望网站能够尽量地自动 处理由于照片变动而产生的影响. 照片可以很大, 你希望在网站上可以显示照片 的缩略图.

你可以用传统的文件实现缩略图, 也就是说你可以把照片 image123.jpg 及其缩略图 image123-thumbnail.jpg 放在同一个目录里. 如果你 希望照片及其缩略图能使用相同的文件名, 也可以把缩略图放在不同的目录里, 例如 thumbnails/image123.jpg. 你可以按照类似的方 法存放标题和日期. 这里最大的问题是每增加一个新图片, 网站的文件数量都 会成倍地增加.

现在考虑如果利用 Subversion 的文件属性来部署网站. 设想有一个图片 文件 image123.jpg, 带有属性 caption, datestamp 和 thumbnail. 使用属性后的工作副本看起来更容量管理 —实际上, 普通的浏览器只能看到图片文件, 但是你的自动化管理脚本 可以知道得更多. 脚本可以使用 svn (更好的做法是用 Subversion 的语言绑定—见 the section called “Using the APIs”) 获取图片的属性信息, 而不必读取索引文件或处理路径.

自定义版本号属性也经常用到, 一种常见的用法是为版本号添加一个包含 问题跟踪 ID 的属性, 表示该版本号修复了这个问题. 其他一些用法还可以 是为版本号附加一个更友好的名字—人们很难记住版本号 1935 是一个 经过充分测试的版本, 但是如果给版本号 1935 添加一个属性 test-results, 属性值是 all passing, 这样一来就方便多了. 用户可以通过 svn commit 的选项 --with-revprop 为新提交的版本号附加属性 test-results:

```
$ svn commit -m "Fix up the last remaining known regression bug." \
             --with-revprop "test-results=all passing"
Sending        lib/crit_bits.c
Transmitting file data .
Committed revision 912.
$
```

### 操作属性

命令 svn 提供了几种用于添加或修改文件和目录 属性的方法. 如果属性的值比较短, 而且是人类可读的, 那么添加新属性的 最简单的方法是在子命令 svn propset 的命令行参 数上指定属性名和值:

```
$ svn propset copyright '(c) 2006 Red-Bean Software' calc/button.c
property 'copyright' set on 'calc/button.c'
$
```

Subversion 对于属性值给予了很大的灵活性, 如果属性值包含多行文本, 甚至是二进制格式, 此时用户就不太可能把值写在命令行参数上, 为了解决 这个问题, svn propset 支持选项 --file (-F), 该选项指定了一个包含 属性值的文件的名字.

```
$ svn propset license -F /path/to/LICENSE calc/button.c
property 'license' set on 'calc/button.c'
$
```

对属性名有一些限制条件, 属性名必须以字母, 冒号 `:`或下划线 `_` 开始, 接下来的字符, 除了前面介绍的, 还可 以用数字, 连字符 `-`, 句点 `.`. [12]

除了 propset, svn 还提供了 子命令 propedit. propedit 使用 预先配置的外部编辑器 (见 the section called “General configuration”) 来添加或修改属性. 执行 svn propedit 时, 命令在一个临时文件上打开 编辑器, 临时文件的内容是属性的当前值 (如果是添加新属性, 内容就是空的), 然后用户就可以按照自己的需要在编辑器里修改属性值, 修改完成后保存临时 文件, 最后退出编辑器. 退出编辑器后, 如果 Subversion 检测到属性原来的 值被修改了, 它就把修改后的值当作属性的新值. 如果用户没有修改便退出 编辑器, 属性值就保持不变:

```
$ svn propedit copyright calc/button.c  ### exit the editor without changes
No changes to property 'copyright' on 'calc/button.c'
$
```
应该注意到, 和 svn 的其他子命令一样, 属性操作 可以同时施加到多个路径上, 这就允许用户用一个命令修改整个文件集合的属性, 例如我们可以这样做:

```
$ svn propset copyright '(c) 2006 Red-Bean Software' calc/*
property 'copyright' set on 'calc/Makefile'
property 'copyright' set on 'calc/button.c'
property 'copyright' set on 'calc/integer.c'
…
$
```
如果用户不能方便地获取属性值, 那么属性的添加和删除就没什么大用处, 所以 svn 提供了两个子命令用于显示文件和目录上的 属性名和值. 命令 svn proplist 列出指定路径上的属性 的名字, 一旦知道了属性名, 就可以用命令 svn propget 分别地获取各个属性的值, 它根据指定的属性名和一个路径 (或多个路径) 打印 出属性的值.

```
$ svn proplist calc/button.c
Properties on 'calc/button.c':
  copyright
  license
$ svn propget copyright calc/button.c
(c) 2006 Red-Bean Software
```
执行命令 svn proplist 时如果加上选项 --verbose (-v), 命令就会同时列出 所有属性的名字和值.

```
$ svn proplist -v calc/button.c
Properties on 'calc/button.c':
  copyright
    (c) 2006 Red-Bean Software
  license
    ================================================================
    Copyright (c) 2006 Red-Bean Software.  All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:

    1. Redistributions of source code must retain the above copyright
    notice, this list of conditions, and the recipe for Fitz's famous
    red-beans-and-rice.
```

最后一个与属性相关的子命令是 propdel. 因为 Subversion 允许为属性设置空值, 所以用户不能想当然地认为用 svn propedit 和 svn propset 把属性值设置成空值, 就能实现完全删除属性的效果, 比如说下面的命令不会产 生用户想要的效果 (用户想要的效果是删除属性 license) :

```
$ svn propset license "" calc/button.c
property 'license' set on 'calc/button.c'
$ svn proplist -v calc/button.c
Properties on 'calc/button.c':
  copyright
    (c) 2006 Red-Bean Software
  license

$
```

为了完全删除属性, 需要使用子命令 propdel, 它的使用语法和其他属性命令类似:

```
$ svn propdel license calc/button.c
property 'license' deleted from 'calc/button.c'.
$ svn proplist -v calc/button.c
Properties on 'calc/button.c':
  copyright
    (c) 2006 Red-Bean Software
$
```
还记得那些非版本化的版本号属性吗? 用户也可以用我们刚刚介绍过的 svn 的子命令去修改它们, 只要加上选项 --revprop 和欲修改的版本号. 因为版本号是全局的, 所以 只要用户已经位于欲修改的版本号的工作副本中, 就不需要为命令指定目标路径, 否则的话, 可以在命令行上提供目标路径的 URL 参数. 例如, 用户可能想修改 一个已存在的版本号的提交日志,[13] 如果你的当前工作目录是工作副本的一 部分, 可以不带目标路径地执行命令 svn propset:

```
$ svn propset svn:log "* button.c: Fix a compiler warning." -r11 --revprop
property 'svn:log' set on repository revision '11'
$
```
即使用户没有检出仓库的工作副本, 仍然可以通过提供仓库的根 URL 来 修改属性:

```
$ svn propset svn:log "* button.c: Fix a compiler warning." -r11 --revprop \
              http://svn.example.com/repos/project
property 'svn:log' set on repository revision '11'
$
```
需要注意的是只有在仓库管理员配置后用户才能修改非版本化属性 (见 the section called “修正提交日志消息”). 这是因为如果属性是非 版本化的, 用户一不小心就有可能弄丢信息. 仓库管理员可以采取一定的措施 防止信息丢失, 在默认上, 修改非版本化属性是被禁止的.

### 属性和 Subversion 工作流程

既然读者已经熟悉了所有与属性相关的 svn 子命令, 现在来看属性修改将会如何影响 Subversion 的工作流程. 我们已经说过, 文件和目录的属性是被版本控制的, 就像文件内容那样, 因此 Subversion 也 支持属性的合并—或干净利落地, 或带有冲突.

和文件内容一样, 属性修改一开始只是本地的, 只有用 svn commit 提交后, 属性的修改才会持久化. 属性的修改 也能轻易地撤消—命令 svn revert 可以撤消所有 文件和目录的本地修改, 包括属性修改, 内容修改, 以及其他所有的本地修改. 你也可以用 svn status 和 svn diff 获取文件和目录的属性状态.

```
$ svn status calc/button.c
 M      calc/button.c
$ svn diff calc/button.c
Property changes on: calc/button.c
___________________________________________________________________
Added: copyright
## -0,0 +1 ##
+(c) 2006 Red-Bean Software
$
```
注意, 子命令 status 把 M 显示 在了第二列, 而不是第一列, 这是因为我们修改的是 calc/button.c 的属性, 而不是内容. 如果我们同时修改 了内容和属性, 我们就会同时在第一列和第二列看到 M (我们在 the section called “查看修改的整体概述” 介绍了 svn status).

### 继承的属性

Subversion 1.8 引入了继承属性这个概念. 将一个属性设置成可继承的 并没有什么很特别的地方, 实际上, 所有版本化的属性都是可继承的! 1.8 前 的版本化属性和 1.8 后的版本化属性的主要区别是后者支持在一个目标路径 的 父路径 (parents) 上搜索 属性, 即使这些父路径在工作副本里不存在.

有些命令可以显示出一般的属性继承, 首先 svn proplist 和 svn propget 可以检索 URL 的或工作副本路径的父路径 上的所有属性, 方法是带上选项 --show-inherited-props. 读者可能会觉得这是选项 --recursive 的反面—选项 --recursive 向 “下” 递归到目标的子目录里, 而 --show-inherited-props 是向 “上” 看 目标的父目录. 命令 svnlook propget 和 svnlook proplist 按照类似的方法使用选项 --show-inherited-props.

举个例子, 在工作副本的根目录递归地调用 propget , 发现子命令的目标路径及其中的一个子目录 site 都设置了属性 svn:auto-props:

```
$ svn pg svn:auto-props --verbose -R .
Properties on '.':
  svn:auto-props
    *.py = svn:eol-style=native
    *.c = svn:eol-style=native
    *.h = svn:eol-style=native

Properties on 'site':
  svn:auto-props
    *.html = svn:eol-style=native
```

如果我们把子目录 site 作为子命令的目标路径, 然后使用选项 --show-inherited-props, 我们将会看到属性 svn:auto-props 存在于目标路径 和 它的父路径上, 父路径的属性是 “被继承的”:

```
$ svn pg svn:auto-props --verbose --show-inherited-props site
Inherited properties on 'site',
from '.':
  svn:auto-props
    *.py = svn:eol-style=native
    *.c = svn:eol-style=native
    *.h = svn:eol-style=native

Properties on 'site':
  svn:auto-props
    *.html = svn:eol-style=native
```
在上一个例子里, 工作副本的根目录对应仓库的根目录, 但即使没有这种 对应, 属性也可以从工作副本的外面继承. 现在检出上一个例子的 site 目录, 使它成为工作副本的根目录:

```
$ svn co http://svn.example.com/repos site-wc
A    site-wc/publish
A    site-wc/publish/ch2.html
A    site-wc/publish/news.html
A    site-wc/publish/ch3.html
A    site-wc/publish/faq.html
A    site-wc/publish/index.html
A    site-wc/publish/ch1.html
 U   site-wc
Checked out revision 19.

$ cd site-wc
```
当我们在一条工作副本路径上检查继承的属性时将会看到, 一个属性继承 自工作副本里的父目录, 一个属性继承自仓库里的父路径, 该路径在工作副本 的根目录的 “上层”:

```
$ svn pg svn:auto-props --verbose --show-inherited-props publish
Inherited properties on 'publish',
from 'http://svn.example.com/repos':
  svn:auto-props
    *.py = svn:eol-style=native
    *.c = svn:eol-style=native
    *.h = svn:eol-style=native

Inherited properties on 'publish',
from '.':
  svn:auto-props
    *.html = svn:eol-style=native
```

前面已经说过, svnlook proplist 和 svnlook propget 也支持选项 --show-inherited-props, 但它们不是以工作副本路径或 URL 作为目标路径, 而是以仓库的路径作为目标路径:

```
$ svnlook pg repos svn:auto-props /site/publish --show-inherited-props -v
Inherited properties on '/site/publish',
from '/':
  svn:auto-props
    *.py = svn:eol-style=native
    *.c = svn:eol-style=native
    *.h = svn:eol-style=native

Inherited properties on '/site/publish',
from '/site':
  svn:auto-props
    *.html = svn:eol-style=native
```

当工作副本被首次检出或者更新时, 从工作副本根目录上层继承而来的属性 会被缓存在工作副本的管理数据库里, 这样的话在查看继承的属性时就不用再 访问仓库了, 同时也允许那些不要求访问仓库的子命令 (例如 svn add ) 在保持 “无连接” 的同时, 仍然可以访问到从工作 副本之外的路径继承而来的属性. 但同时也意味着在最近一次更新之后, 来自工 作副本根目录上层的继承属性可能已经发生了变化, 使得本地缓存变成过时了的. 所以如果用户要求继承的属性始终是最新的, 最好更新一下工作副本或直接询问 仓库.

到这里读者可能会想 “看起来挺有趣的, 但这有什么好处呢? ” 对于属性继承本身来说是没多大用处, 在 1.8 之前, Subversion 所有的保留属性 svn:* (还可能包括所有的用户自定 义属性) 都只能应用到它们所在的路径上, 至多再加上直接子路径 [14]. Subversion 使用继承属性完成另一些更有趣的事情, 比如说用 属性 svn:auto-props 设置自动属性, 用属性 svn:global-ignores 实现全局的忽略模式— 关于这些特殊属性的更多信息和使用方法, 见 the section called “自动属性设置” 和 the section called “忽略未被版本控制的项目”.

### 自动属性设置

属性是 Subversion 最强大的特性之一, 它是本章和其他章节介绍的众多 Subversion 特性—文本差异比较, 合并支持, 关键字替换和换行符转换 等—的关键基础. 为了充分发挥属性的作用, 它们必须被设置到正确的 文件和目录上, 不幸的是, 这个步骤在日常工作中常常被人遗忘, 尤其是因为 即使属性设置不当通常也不会造成很明显的错误 (至少和文件添加失败比起 来, 不是很明显). 为了帮助用户更好地使用属性, Subversion 提供了几个 简单但很有用的特性.

每当用户使用 svn add 和 svn import 向仓库添加文件时, Subversion 自动地在文件上设置一些常见的 属性. 首先, 如果操作系统的文件系统支持可执行权限位并且文件具有可执行 权限, Subversion 就自动在文件上设置 svn:executable 属性 (关于这个属性的更多信息, 见 the section called “文件的可执行性”).

然后, Subversion 会试图判断文件的 MIME 类型. 如果用户为 mime-types-files 设置了一个运行时配置参数, Subversion 就会尝试根据文件的后缀名为文件搜索一个对应的 MIME 类型映射, 若找到的话, 它就把文件的 svn:mime-type 属性设置成找到的 MIME 类型. 如果用户没有为 mime-types-files 设置运行时 配置参数, 或者根据后缀名没有找到对应的类型映射, Subversion 就使用启发 式的算法来判断文件的 MIME 类型. 取决于编译时的配置, Subversion 1.7 可以利用文件扫描函数库[15] 检测文件的类型. 如果前面的都失败了, Subversion 就 使用它非常基本的启发式算法来判断文件是否包含非文本数据, 如果是, 就自动 地把文件的 svn:mime-type 属性设置成 application/octet-stream (最一般的 MIME 类型, 表示 “这是字节的集合”). 当然, 如果 Subversion 的判断不正确, 又或者是用户想把 svn:mime-type 设置成更精确的值 —比如 image/png 或 application/x-shockwave-flash—可以自由地修改或删除 属性 svn:mime-type (关于 Subversion 如何使用 MIME 类型的更多信息, 见本章后面的 the section called “文件内容类型”).

借助运行时配置系统 (见 the section called “Runtime Configuration Area”), Subversion 提供了一种更加灵活的自动属性设置功能, 它允许用户创建文件名 模式到属性名和值的映射. 再说一次, 这些映射会影响 svn add 和 svn import, 除了会 覆盖由 Subversion 判断出的默认 MIME 类型, 还可能添加额外的属性或自定义 属性. 例如, 用户想创建一个映射, 这个映射是说每次添加一个 JPEG 文件时 —文件的名字符合模式 \*.jpg —Subversion 都应该自动地把这个文件的 svn:mime-type 属性设置为 image/jpeg. 又或者说匹配模式 \*.cpp 的文件都应该把 svn:eol-style 设置成 native , 把 svn:keywords 设置成 Id . 关于运行时配置如何支持自动属性的更多细节, 见 the section called “General configuration”.

虽然借助运行时配置系统来支持自动属性设置非常方便, 但 Subversion 管理员可能更希望当客户端工具在一个从特定服务器检出的工作副本上工作 时, 可以考虑到那些自动连接到客户端的属性集合. Subversion 1.8 及其 之后的客户端版本通过可继承属性 svn:auto-props 实现这个功能.

属性 svn:auto-props 可以像运行时配置系统那样, 自动地为新增的文件设置属性, 属性 svn:auto-props 的值应该和运行时配置选项 auto-props 的值相同 (也 就是任意数量的键值对, 格式是 FILE_PATTERN = PROPNAME=VALUE[;PROPNAME=VALUE ...]). 和运行时选项 auto-props 一样, 如果使用了选项 --no-auto-props, 属性 svn:auto-props 就会被忽略, 但是有所不同的是, 即使配置选项 enable-auto-props 被设置为 no, 属性 svn:auto-props 也不会被禁止.

举例来说, 你检出了主干的工作副本, 想在其中添加一个新文件 (假设 运行时配置系统禁止了自动属性):

```
$ svn st
?       calc/data.c

$ svn add calc/data.c
A         calc/data.c

$ svn proplist -v calc/data.c
Properties on 'calc/data.c':
  svn:eol-style
    native
```

可以看到, 当 data.c 被版本控制后, 文件自动 设置了属性 svn:eol-style. 因为运行时配置选项 auto-props 是禁止了的, 所以属性 svn:auto-props 肯定来自 data.c 的 父路径. 执行带上选项 --show-inherited-props 的命令 svn propget 可以看到, 事实的确是如我们所想的那样:

```
$ svn propget svn:auto-props --show-inherited-props -v calc
Inherited properties on 'calc',
from 'http://svn.example.com/repos':
  svn:auto-props
    *.py = svn:eol-style=native
    *.c = svn:eol-style=native
    *.h = svn:eol-style=native
```

属性 svn:global-ignores 及其对应的运行时配置 选项 global-ignores 是一起起作用, 但属性 svn:auto-props 和运行时选项 auto-props 的关系就不这样, 如果运行时选项 auto-props 在一个模式上设置了一个自动属性, 而 属性 svn:auto-props 也在 同一个 模式上设置了自动属性, 那么属性的设置就会覆盖运行时配置选项的设置. 从一个路径继承而来的自动属性 [16]也只会覆盖从其他路径继承的 同一个 模式. 覆盖的先后顺序是:

在 svn:auto-props 上定义的, 针对某一模式的 自动属性会覆盖运行时配置选项 auto-props 上设置 的同一模式的自动属性.

对于一个给定的模式而言, 如果它的自动属性继承自多个父路径的 svn:auto-props 属性, 那么在路径上最近的父路径 的自动属性会覆盖其中父路径.

对一个给定的模式而言, 如果在路径的 svn:auto-props 属性上显式地设置了一个自动属性, 那它就会覆盖从其他路径 继承而来的相同模式上的自动属性.

举例来说, 假设你有一个如下所示的运行时配置:

```
[miscellany]
enable-auto-props = yes
[auto-props]
*.py  = svn:eol-style=CR
*.c   = svn:eol-style=CR
*.h   = svn:eol-style=CR
*.cpp = svn:eol-style=CR
```

你想添加 calc 目录中的三个文件:

```
$ svn st
?       calc/data-binding.cpp
?       calc/data.c
?       calc/editor.py
```
先看一下 calc 的 svn:auto-props 属性:

```
$ svn propget svn:auto-props -v --show-inherited-props calc
Inherited properties on 'calc',
from 'http://svn.example.com/repos':
  svn:auto-props
    *.py = svn:eol-style=native
    *.c = svn:eol-style=native
    *.h = svn:eol-style=native

Inherited properties on 'calc',
from '.':
  svn:auto-props
    *.py = svn:eol-style=native
    *.c = svn:keywords=Author Date Id Rev URL
```
添加这三个文件, 然后检查它们的自动属性:

```
$ svn add calc --force
A         calc/data-binding.cpp
A         calc/data.c
A         calc/editor.py
```

文件 data-binding.cpp 只有一个匹配的模式, 也就是运行时配置选项里的 *.cpp = svn:eol-style=CR, 显然文件的属性 svn:eol-style 被设置为 CR :

```
$ svn proplist -v calc/data-binding.cpp
Properties on 'calc/data-binding.cpp':
  svn:eol-style
    CR
```
文件 editor.py 既匹配运行时配置选项里的一 条模式, 也匹配属性 svn:auto-props 里的模式, 根据前 面介绍的覆盖顺序, 显式设置在 calc 上的属性值 (*.py = svn:eol-style=native) 的优先级较高, 所以 属性 svn:eol-style 被设置为 native :

```
$ svn proplist -v calc/editor.py
Properties on 'calc/editor.py':
  svn:eol-style
    native
```
文件 data.c 同时匹配运行时配置选项和继承属性 svn:auto-props 的模式. 自动属性 svn:keywords 只被定义了一次, 在 calc 上定义, 所以 data.c 自动获取了该属性. calc 上的 svn:auto-props 没有 为 svn:eol-style 定义值, 所以最近的父路径 http://svn.example.com/repos 提供了这个值:

```
$ svn proplist -v calc/data.c
Properties on 'calc/data.c':
  svn:eol-style
    native
  svn:keywords
    Author Date Id Rev URL
```

svn:auto-props 最后一个需要注意的地方是它 (以 及类似的 svn:global-ignores, 见 the section called “忽略未被版本控制的项目”) 只是向理解属性 的客户端工具提供了一个建议, 较老的客户端会忽略这些属性, 选项 --no-auto-props 会忽略它们, 用户可能会选择手动地修改 或删除自动属性—有很多方法可以旁路掉包含在 svn:auto-props 里的推荐属性. 因此, 管理员仍然需要使用钩子脚本验证文件和 目录上的属性是否符合管理员的策略, 并拒绝与策略不兼容的提交 (钩子脚本见 the section called “忽略未被版本控制的项目”).

### Subversion 的保留属性

本节将对 Subversion 所有的保留属性做一个简单的总结, 包括版本化的 的属性 (和文件, 目录关联) 与非版本化的属性 (和版本号关联).

#### 版本化的属性

这些是 Subversion 保留给自己用的版本化属性:

* **svn:auto-props** 该属性包含了一系列的自动属性定义, 如果被设置在一个目录上, 那么自动属性定义会应用到目录内的所有文件, 见 the section called “自动属性设置”.
* **svn:executable** 如果该属性被设置到一个文件上, 那客户端就会给 Unix 工作副本里 的文件设置上可执行权限, 见 the section called “文件的可执行性”
* **svn:mime-type** 如果属性出现在一个文件上, 那么属性值指出了文件的 MIME 类型, 当更新时, 属性可以帮助客户端判断是否可以安全地对文件进行基于行 的合并操作. 另外, 当用户通过网页浏览器获取文件时, 该属性还会影 响文件的具体行为. 更多的信息参考 the section called “文件内容类型”.
* **svn:ignore** 如果该属性出现在一个目录上, 属性值是一个未被版本化的文件 模式列表, 符合模式的文件会被 svn status 和 其他子命令忽略, 见 the section called “忽略未被版本控制的项目”.
* **svn:global-ignores** 如果该属性出现在一个目录上, 属性值是一个未被版本化的文件 模式列表, 符合模式的文件会被 svn status 和 其他子命令忽略, 但是和 svn:ignore 不同的是, 这些模式会应用到目录内 所有的 子目录及其 子文件, 而不仅仅是目录的直接子文件, 见 the section called “忽略未被版本控制的项目”.
* **svn:keywords** 如果该属性出现在一个文件上, 属性的值指出了客户端应该如何 扩展文件内的特定关键字, 见 the section called “关键字替换”.
* **svn:eol-style** 如果该属性出现在一个文件上, 则属性的值指出了客户端应该如何 处理工作副本和导出目录里的文件的行终止符, 见 the section called “行结束标记” 和 svn export.
* **svn:externals** 如果该属性出现在一个目录上, 则属性的值是一个包含了多个路径 和 URL 的列表, 这些路径和 URL 都是客户端需要检出的内容, 见 the section called “外部定义”.
* **svn:special** 如果该属性出现在一个文件上, 则表示该文件不是一个普通的文件, 可能是一个符号链接或其他特殊的对象[17]
* **svn:needs-lock** 如果该属性出现在一个文件上, 客户端就会把工作副本里的这个 文件设置成只读, 也就是提醒用户在编辑文件之前需要加锁, 见 the section called “锁通信”.
* **svn:mergeinfo** Subversion 使用该属性跟踪合并信息, 更多的细节见 the section called “合并信息和预览”, 除非你 真得 知道自己在做什么, 否则不要 编辑该属性.

#### 未版本化的属性

下面是保留给 Subversion 私用的版本化的 (或版本号) 属性, 它们中 的大部分都会出现在仓库的每个版本号上, 属性携带了关于修改的起因与 本质.

* **svn:author** 如果设置了该属性, 则属性包含了创建此版本号用户名, 如果没有该属性, 那么版本号是匿名提交的.
* **svn:autoversioned** 如果设置了该属性, 则说明版本号是通过自动版本化特性创建的, 见 the section called “Autoversioning”.
* **svn:date** 包含了版本号创建时的 UTC 时间, 使用 ISO 8601 格式, 时间来自 服务器 的机器时钟, 而不是客户 端的时钟.
* **svn:log** 包含了描述版本号的日志消息.
* **svn:rdump-lock** 为 svnrdump load 访问仓库临时施加互斥 性, 通常只有在 svnrdump load 活动时— 或者在 svnrdump 不能干净地与仓库断开连接时 —该属性才会被观察到 (只有当这个属性出现在版本号 0 上时, 它才是有意义的).
* **svn:sync-currently-copying** 包含了源仓库中已经被 svnsync 镜像备份 的版本号 (只有当这个属性出现在版本号 0 上时, 它才是有意义的).
* **svn:sync-from-uuid** 包含了由 svnsync 创建的镜像的源仓库的 UUID (只有当这个属性出现在版本号 0 上时, 它才是有意义的).
* **svn:sync-from-url** 包含了由 svnsync 创建的镜像的源仓库目录 的 URL (只有当这个属性出现在版本号 0 上时, 它才是有意义的).
* **svn:sync-last-merged-rev** 包含了最近一次被成功地镜像备份的源仓库的版本号 (只有当这 个属性出现在版本号 0 上时, 它才是有意义的).
* **svn:sync-lock** 为 svnsync 的镜像操作临时添加仓库访问 的互斥性, 通常只有在 svnsync 活动时— 或者在 svnsync 不能干净地与仓库断开连接时, 只有当这个属性出现在版本号 0 上时, 它才是有意义的).

## 文件的可移植性

对于经常需要在不同的操作系统中工作的用户来说, 比较幸运的一点是 Subversion 命令行工具在所有系统中的表现几乎都是相同的, 如果用户已经知道 了如何在一种系统中使用 svn, 那他也就知道了如何在其他 系统中使用 svn.

然而, 其他软件或存放在 Subversion 仓库里的文件并不都是这样. 比如说 在一台 Windows 机器上, 对于 “文本文件” 定义和 Linux 机器类 似, 除了一点—标记一行结束的字符序列不同. 除此之外, Unix 平台 (和 Subversion) 支持符号链接, 而 Windows 不支持; Unix 平台根据文件系统权限 来判断文件的可执行性, 而 Windows 是根据文件的扩展名.

Subversion 并不想把整个世界都统一到公共的定义和实现上, 当用户要在多 种不同的操作系统中管理文件与目录时, 它所能做的只是尽量减少用户的麻烦. 本节介绍 Subversion 如何帮助用户在多种不同的平台中使用 Subversion.

### 文件内容类型

和许多应用程序一样, Subversion 也会使用 MIME (多用途互联网邮件扩展 类型, Multipurpose Internet Mail Extensions) 内容类型. 属性 svn:mime-type 除了可以作为文件内容类型的存放位置, 它的值还决定了 Subversion 的某些行为特征.

比如说, Subversion 提供的一项特性是在更新工作副本时, 支持基于行 的文件内容合并, 但是二进制文件没有 “行” 的概念, 于是, 如果文件的 svn:mime-type 属性被设置成非文本 MIME 类型 (非文本的 MIME 类型通常不以 text/ 开始, 但是也有 例外), Subversion 就不会对文件执行合并操作. 作为替代, 如果被更新的二 进制文件含有本地修改, 那文件就不会被更新, Subversion 会另外创建两个 新的文件, 其中一个的扩展名是 .oldrev, 对应文件的 BASE 版本号; 另一个的扩展名是 .newrev, 对应更新 后的版本号. 这样做是为了避免对不支持合并的文件进行合并而带来的错误.

另外, 为了能够以行为单位显示修改, 文件必须能被划分成 “行”, 如果 svn diff 和 svn annotate 的目标文件的 MIME 类型是非文本的, 这 两个命令默认会报错. 如果用户的文件是 XML 文件, 它们的 svn:mime-type 被设置成 application/xml, 虽然它们是人类可读的文本文件, 但 Subversion 仍然会把它们看成是非文本 文件, 幸好, 为命令添加选项 --force 可以强制 Subversion 不管文件的 MIME 类型, 直接执行操作.

Subversion 提供了多种用于自动设置属性 svn:mime-type 的机制, 详细的介绍见 the section called “自动属性设置”.

另外, 如果文件设置了属性 svn:mime-type, 响应 GET 请求时, Subversion Apache 模块将会使用属性的值填充 HTTP 头部的 Content-type 字段. 如果用户使用浏览器查看仓库的内容, 这可以提示浏览器应该如何显示文件.

### 文件的可执行性
在很多操作系统里, 一个文件是否可以执行取决于该文件是否设置了 可执行权限位. 该位默认是不开启的, 如果用户需要可执行权限, 必须显式地 开启它. 但是记住应该为哪些检出的文件设置可执行位是一件很麻烦的事情, 所以 Subversion 提供了属性 svn:executable, 如果文件 设置了该属性, Subversion 就会在工作副本里打开文件的可执行位.

该属性对不支持可执行位的文件系统是没有效果的, 比如 FAT32 和 NTFS. [19] 另外, 尽管该属性 没有预定义的值, 在设置属性时, Subversion 强制把它的值设置为 \*. 最后, 该属性只对文件有效, 对目录不起作用.

### 行结束标记

除非属性 svn:mime-type 进行了额外说明, 否则 Subversion 总是假设文件的内容是人类可读的. 一般来说, Subversion 会根据 自己的知识来判断是否可以对文件进行基于上下文的差异比较, 如果不能的话, 就 按字节比较差异.

Subversion 默认情况下并不关心文件的 行结束 (EOL) 标记 (end-of-line (EOL) markers ) 类型. 不幸的是, 如何结束一行, 不同的操作系统有着不同的约 定. 比如说, Windows 软件使用一对 ASCII 控制字符表示一行的结束— 一个回车符 (CR) 后面再跟一个换行符 (LF ); 而 Unix 系统中的软件只用单一的换行符 (LF ) 表示一行的结束.

如果文件的行结束标记与操作系统的 本地的行结束风格 不同, 有些软件可能无法正确地处理这种文件. 所以在典型情况 下, Unix 程序把来自 Windows 的文件里的回车符 (CR) 当 成一个普通字符 (通常显示成 ^M), 而 Windows 程序会 把来自 Unix 系统的文件显示成一段很长的行, 因为它们找不到用来结束一行 的回车符 (CR).

如果用户要在不同的操作系统之间分享文件, 如此敏感的 EOL 标记可不 是什么好事. 比如说有一个源代码文件, 开发人员可能会同时在 Unix 和 Windows 系统中编辑它, 如果所有开发人员使用的工具都能保留文件原来的行 结束风格, 那就不会产生什么问题.

可惜的是, 如果文件的行结束标记和本地不同, 很多程序要么不能正确地读 取并显示文件, 要么在保存时, 把文件的行结束标记转换成本地风格. 如果是前 一种情况, 开发人员在开始编辑文件之前, 需要使用一种格式转换工具 (比如 dos2unix 及其伙伴 unix2dos) 把 文件的行结束标记转换成本地风格. 如果是后一种情况就不用在编辑之前转换文件 格式. 但是两种情况都会导致文件的每一行都发生变化! 在提交修改之前, 用户 有两种选择, 一是使用格式转换工具把文件的行结束标记转换成与原来一样的 风格, 二是直接提交—使用新的行结束标记.

这种情况的结果是既浪费了时间, 也提交了很多没必要的修改. 浪费时间 已经足够烦人了, 更糟糕的是一次提交修改了文件的每一行, 这会给后面的历史 查询带来很大的麻烦—是哪几行修改解决了问题, 或者是哪一行修改引入 了语法错误.

问题的解决办法是使用属性 svn:eol-style. 如果属 性的值是有效的, Subversion 将根据属性值对文件进行特殊的处理, 这样文件 的行结束风格就不会随着操作系统的变化而变化. 属性的有效值包括:

* **native** 文件的行结束标记是操作系统的本地风格, 换句话说, 如果一个用户 在 Windows 操作系统上检出了工作副本, 文件的 svn:eol-style 被设置成 native, 则文件将使用 CRLF 作为行结束标记. 而 Unix 用户 检出的文件的行结束标记是 LF.

* > 注意, 不管操作系统是什么类型, Subversion 仓库中存放的文件 的行结束标记总是 LF, 这对用户来说是透明的.

* **CRLF** 无论是什么操作系统, 文件总是使用 CRLF 作为行结束标记.
* **LF** 无论是什么操作系统, 文件总是使用 LF 作为 行结束标记.
* **CR** 无论是什么操作系统, 文件总是使用 CR 作为行结束标记. 这种行结束标记用得很少.

## 忽略未被版本控制的项目

在一个长时间使用的工作副本里, 除了被版本控制的文件和目录外, 常常 还有很多未被版本控制的文件与目录, 而且它们将来也不会被添加到仓库里, 这 些文件可能是文本编辑器的备份文件, 或编译器产生的目标文件, 对它们进行版 本控制是没有意义的, 用户随时都有可能把它们删除.

希望工作副本不受这些杂质影响是不可能的. 实际上这是 Subversion 的一个 特性, 那就是对操作系统来说工作副本就是一个普通的目录, 与未被版本化的 目录相比并没有本质上的区别. 不过工作副本里的未被版本化的文件和目录会给 用户产生一定的困扰. 比如说, 命令 svn add 和 svn import 默认会递归地执行, 命令并不知道目录中的哪些 文件是用户想要的, 哪些是不想要的. 命令 svn status 默认报告工作副本里的每一个项目的状态—包括未被版本控制的文件与目 录—如果未被版本控制的项目很多, 命令的输出就比较扰人.

于是, Subversion 提供了几种方式告诉 Subversion 哪些文件是可以忽略的. 其中一种要用到 Subversion 的运行时配置系统 (见 the section called “Runtime Configuration Area”), 会受到配置影响的通常是在特定 计算机上执行的 Subversion 操作, 或计算机上的某些特定用户. 另外两种方式 用到了 Subversion 的目录属性, 与版本化目录的联系更为紧密, 因此它会影响 到版本化目录的所有工作副本. 上面说的两种机制都会用到 文件模式 (file patterns) (用于匹配文件名的字符串, 包含了字面字符与通配符) 来决定应该忽略哪些 文件.

Subversion 运行时配置系统提供了一个选项—global-ignores —选项的值是空白符分隔的文件名模式集. 如果文件的名字 与集合中的某个模式匹配, 那这个文件对 Subversion 来说相当于是不存在的, 命令 svn add, svn import 和 svn status 就会忽略它. 如果工作副本里有永远不会 被版本控制的文件 (比如 Emacs 的备份文件 \*~ 和 .\*~), 这个特性就会非常有用.

如果被版本控制的目录上设置了属性 svn:ignore, 属性值应该是一个文件名模式列表, 各项之间用换行符分开, Subversion 根据 文件名模式列表判断 相同 目录内的哪些文件是可以忽略 的. 属性 svn:ignore 不会覆盖运行时配置选项 global-ignores 的值, 而是作为一种补充. 与 global-ignores 不同的是, 属性 svn:ignore 里的模式只能作用在该属性所在的目录上, 不会递归作用到子目录上. 属性 svn:ignore 的一个常用目的是告诉 Subversion 去忽略每个 用户的工作副本中可能都会有的文件, 例如编译器的输出文件—对于本书而 言, 就是 HTML, PDF, PostScript 文件, 或其他 DocBook XML 转换过程中产生 的临时文件和输出文件.

Subversion 1.8 提供了一个比 svn:ignore 更强大的 属性—svn:global-ignores. 和 svn:ignore 相同的是, svn:global-ignores 只能设置到目录上, 属性值是文件名模式集合.[20] svn:global-ignores 定义的文件名模式会添加到运行时配置选项 global-ignores 与 属性 svn:ignore 定义的模式上. 与 svn:ignore 不同的是, svn:global-ignores 是可继承的 [21], 它会递归地作用到目录内的 所有 路径上, 而不仅仅是目录的直接子文件.

运行时配置选项 global-ignores 里的忽略模式更 倾向于个人化 [22], 并且和工作副本相比, 更贴近用户的个人需求. 所以, 本节的余 下部分主要关注 svn:ignore, svn:global-ignores 及如何使用它们.

假设某个工作副本的 svn status 输出是:

```
$ svn status calc
 M      calc/button.c
?       calc/calculator
?       calc/data.c
?       calc/debug_log
?       calc/debug_log.1
?       calc/debug_log.2.gz
?       calc/debug_log.3.gz
```

在上面的例子里, 用户已经修改了 button.c, 但是 工作副本里还有一些未被版本控制的项目: 刚从源代码编译出的 calculator 程序, 一个叫做 data.c 的 源代码文件, 还有几个用于调试的日志文件. 假设用户已经知道编译系统总是会 输出一个目标文件 calculator[23], 而且测试程序总是会留下一些 调试日志文件, 除了用户自己的工作副本, 该项目所有的工作副本都有可能出现 这些文件. 用户非常清楚地知道, 当他执行 svn status 时, 并不想看到这些他不感兴趣的文件, 而且他也相信其他人也对它们不感兴趣. 于是, 用户决定为目录 calc 设置属性 svn:ignore :

```
$ svn propget svn:ignore calc
calculator
debug_log*
$
```
属性设置完毕后, 目录 calc 包含了未被提交的本地 修改. 注意看 svn status 的输出发生了什么变化:

```
$ svn status
 M      calc
 M      calc/button.c
?       calc/data.c
```

现在, 命令的输出变得干净多了! 编辑器产生的目标文件 calculator 和日志文件仍然留在工作副本里, Subversion 只是不 再提醒用户这些文件的存在. 输出变干净后, 用户就能更容易地关注到更重要的 事情上—例如用户可能忘记把源代码文件 data.c 添加到仓库里.

当然, 减少垃圾信息只是一个选择, 如果用户确实想看到所有的文件, 包括 正常情况下会被忽略的文件, 可以给 svn status 加上选项 --no-ignore:

```
$ svn status --no-ignore
 M      calc
 M      calc/button.c
I       calc/calculator
?       calc/data.c
I       calc/debug_log
I       calc/debug_log.1
I       calc/debug_log.2.gz
I       calc/debug_log.3.gz
I       calc/wip.1.diff
```
被隐藏的未被版本控制的项目再度显示出来, 但是在项目的左边加上了字母 I (Ignored). 请等一下, 为什么 wip.1.diff 也有 I? calc 的属性 svn:ignore 里并没有匹配 wip.1.diff 的模式, 那么它为什么会被忽略?[24] 答案是继承的属性 svn:global-ignores. 执行带上选项 --show-inherited-props 的命令 svn propget , 就可以看到属性 svn:global-ignores 被设置 在了工作副本的根目录上, 果然在这个属性里找到了匹配 wip.1.diff 的模式:

```
$ svn pg svn:global-ignores calc -v --show-inherited-props
Inherited properties on 'calc',
from '.':
  svn:global-ignores
    *.diff
    *.patch
```

之前提过, svn add 和 svn import 也会用到忽略模式列表, 这两个操作都会要求 Subversion 开始管理文件与目录. 在递归的添加操作或导入操作中, Subversion 不会要求用户去选择目录 中的哪些文件应该被版本控制, 而是使用忽略模式—包括全局的, 每个目录 与继承的—来决定哪些文件应该被忽略. 同样, 用户也可以用选项 --no-ignore 告诉 Subversion 不会忽略任意一个文件.

## 关键字替换

Subversion 支持把 关键字 (keywords )—跟文件有关的一段有用的动态信息—替换成文件 的内容. 关键字提供了与文件最后一次修改有关的信息, 但是每次文件被修改时, 这个信息都会发生变化, 更重要的是, 文件刚被修改后, 除了版本控制系统, 对 任何一个企图保持数据最新的过程都是一场混乱, 如果把工作交给用户, 就很容易 造成信息过时.

比如说用户有一个文档, 他想显示文档最后一次被修改的日期. 他可以要求 文档的每一个作者在他们提交修改之前, 在文档中记录一下本次修改的日期. 但 是很快就会出现, 总有人会忘记记录修改日期. 更好的做法是让 Subversion 去 完成记录时间的操作, 比如说在每次提交时, 把文档中的关键字 LastChangedDate 替换成当时的日期. 通过在文档中放置一个 关键字锚点 (keyword anchor), 用户可以控制关键字的插入位置. 锚点就是一段简单的文本, 格式是 $KeywordName$ .

如果只想单纯地往文件中添加关键字锚点并不会产生什么特别的效果, 除非 用户显式要求 Subversion, 否则的话它决不会执行文本替换操作, 毕竟用户有可 能只是想写一篇介绍如何使用关键字的文档[25], 此时用户当然不希望 Subversion 把 示例中的关键字锚点都替换掉.

为了告诉 Subversion 是否要替换某个文件中的关键字, 我们要再次使用 与属性有关的子命令. 设置在文件上的属性 svn:keywords 决定了文件中的哪些关键词将会被替换, 属性值是空格分隔的关键字名或别名列表.

举个例子, 假设用户一个叫作 weather.txt 的文件, 文件的内容是:

```
Here is the latest report from the front lines.
$LastChangedDate$
$Rev$
Cumulus clouds are appearing more frequently as summer approaches.
```
如果文件上没有设置属性 svn:keywords, Subversion 就不会对文件做什么特别的操作. 现在开启关键字 LastChangedDate 的替换.

```
$ svn propset svn:keywords "Date Author" weather.txt
property 'svn:keywords' set on 'weather.txt'
$
```
文件 weather.txt 此时含有未被提交的属性修改, 但文件的内容并没有发生变化 (除非用户在设置属性之前又修改了文件). 注意 文件还包含了关键字 Rev 的锚点, 但 svn:keywords 的属性值并没有包含关键字 Rev . 如果文件中没有要被替换的关键字, 或者关键字没有出现在 svn:keywords 的属性值里, Subversion 就不会真正地替换 关键字.

属性修改提交后, Subversion 会立刻更新工作副本里的文件, 将其中的关键 字替换成对应的文本. 关键字锚点将会出现替换后的文本, 替换的结果仍然包含 关键字的名字以及两边的美元符 ($). 因为 svn:keywords 的属性值里没有包含对应的关键字, 所以 Rev 没有被替换.

注意我们把属性 svn:keywords 设置成 Date Author, 而关键字锚点则写成了 $LastChangedDate$, 但仍然得到了正确的结果, 这是因为 LastChangedDate 是 Date 的别名.

```
Here is the latest report from the front lines.
$LastChangedDate: 2006-07-22 21:42:37 -0700 (Sat, 22 Jul 2006) $
$Rev$
Cumulus clouds are appearing more frequently as summer approaches.
```
如果其他人向 weather.txt 提交了新的修改, 自己 工作副本里的文件不会自动更新—直到用户显式地更新了工作副本, 此时, weather.txt 的关键字会被重新替换, 以反应最新的修改 时间.

作为锚点出现在文件里的关键字都区分大小写: 用户必须使用大小写正确的 关键字. 同样也要注意属性 svn:keywords 的值也区分大 小写. 为了保持向后兼容, 某几个关键词是不区分大小写的, 但不建议用户使用 这个特性.

Subversion 定义了几个支持替换的关键字, 下面列出这些关键字, 其中一些 关键字拥有别名:

* **Date** 这个关键字描述了仓库中的文件已知的最后一次被修改的时间, 格式类似 于 $Date: 2006-07-22 21:42:37 -0700 (Sat, 22 Jul 2006) $ . 它的别名是 LastChangedDate. 和关 键字 Id 不同 (Id 使用 UTC 时间), Date 会按照本地时区显示日期.
* **Revision** 这个关键字描述了仓库中的文件已知的最后一次被修改的版本号, 显 示格式 类似于 $Revision: 144 $, 它的别名有 LastChangedRevision 和 Rev.
* **Author** 这个关键字描述了仓库中的文件已知的最后一次是被谁修改的, 显示 格式类似 于 $Author: harry $, 它的别名是 LastChangedBy.
* **HeadURL** 这个关键字描述了仓库中的文件的最新版本的完整 URL 路径, 显示格式 类似于 $HeadURL: http://svn.example.com/repos/trunk/calc.c $, 它的别名是 URL.
* **Id** 这个关键字是几个关键字的组合, 它显示的内容类似于 $Id: calc.c 148 2006-07-28 21:30:43Z sally $, 例子的意思是文件 calc.c 最后一次修改是在 2006 年 7 月 28 日, 版本号 148, 作者是 sally. Id 使用 UTC 时间, 而 Date 使用本地时区.
* **Header** 这个关键字和 Id 类似, 但是增加了 HeadURL 的内容, 看起来就像 $Header: http://svn.example.com/repos/trunk/calc.c 148 2006-07-28 21:30:43Z sally $.

在介绍关键字时, (隐式的或显式的) 用到了形容词 “已知的”, 这是因为关键字替换是一个客户端操作, 客户端只能知道最近一次更新工作副本 时从仓库中获取的信息. 如果工作副本一直得不到更新, 即使仓库中的文件已经 修改了, 工作副本里的关键字也不会被替换成更新的信息.

除了前面几个预定义的关键字, Subversion 1.8 允许用户定义新的关键字. 为了定义一个关键字, 给属性 svn:keywords 的值添加 新的记号, 记号的格式是 MyKeyword= FORMAT, 其中 MyKeyword 是关键字的名字 (关键字锚点需要), FORMAT 是一个格式化的字符串, 替换文件中的关 键字时会根据格式字符进行替换.

格式化字符串支持的格式控制符有以下这些:

* **%a** 由 %r 指定的版本号的作者.
* **%b** 文件的 URL 的基本名 (basename).
* **%d** 由 %r 指定的版本号的日期的短格式.
* **%D** 由 %r 指定的版本号的日期的长格式.
* **%P** 文件相对于仓库根目录的路径.
* **%r** 已知的文件最后一次被修改时的版本号 (和用来替换 Revision 的版本号相同).
* **%R** 仓库根目录的 URL.
* **%u** 文件的 URL.
* **%_** 一个空格符 (定义关键字的字符串中不能包含字面空格).
* **%%** 一个百分号 (%).
* **%H** 等价于 %P%_%r%_%d%_%a.
* **%I** 等价于 %b%_%r%_%d%_%a.

可以看到, 很多单独的格式控制字符所表示的信息与预定义的关键字所表示 的信息相同, 但是自定义关键字允许用户得到更灵活和更丰富的信息. 比如说, 用户希望有一个关键字能被替换成文件在仓库里的相对路径, 以及最后一次修改 文件的版本号, 此时就需要自定义一个关键字:

```
$ svn pset svn:keywords "PathRev=%P,%_r%r" calc/button.c
property 'svn:keywords' set on 'button.c'
$
```

接下来用户要把关键字锚点插入到文档的适当位置, 在这个例子里, 关键字 锚点要写成 $PathRev$. 提交修改后, 文件中原来显示 $PathRev$ 的文本, 变成了 $PathRev: trunk/calc/button.c, r23 $.

用户还可以为替换后的字符串指定一个固定的长度. 在关键字名字后面加 两个冒号 (::), 然后是一定个数的空格, 这样就指定了 一个固定长度. 当 Subversion 准备替换关键字时, 如果发现锚点指定了一个固 定长度, Subversion 就只会替换空格部分. 如果替换后的字符串不够长, 不足 的部分就会用空格填充; 如果替换后的字符串不过长, 字符串就会被截断, 并在 截断的地方放置一个 # 字符.

比如说, 你有一个文档, 文档把 Subversion 的关键字按照表格的样式进行 排版, 如果使用原来形式的关键字替换语法, 替换前的文件内容看起来就像:

```
$Rev$:     Revision of last commit
$Author$:  Author of last commit
$Date$:    Date of last commit
```

现在看起来表格的格式还挺工整的, 但是提交后 (开启了关键字替换功能), 文件的内容就变成了:

```
$Rev: 12 $:     Revision of last commit
$Author: harry $:  Author of last commit
$Date: 2006-03-15 02:33:03 -0500 (Wed, 15 Mar 2006) $:    Date of last commit
```
替换后的效果令人感到失望, 用户可能会忍不住手工地调整每一行没对齐的 文本, 但是实际上只要关键字的值占用相同的宽度, 格式就不会被打乱. 如果版本 号增长到比较长的位数 (例如从 99 增长到 100), 或者有一个名字很长的用户提 交了修改, 文件的版式就得重新调整. 如果用户使用的 Subversion 版本大于等于 1.2, 就可以使用具有固定长度的关键字语法, 为了使用这种关键字语法, 把文件 的内容改成:

```
$Rev::               $:  Revision of last commit
$Author::            $:  Author of last commit
$Date::              $:  Date of last commit
```
提交修改, 这次 Subversion 会注意到文件中使用了具有固定长度的关键字语 法, 替换后, 字段的长度保持不变—较短的 Rev 和 Author 使用空格填充不足的部分, 较长的 Date 被井字符截断:

```
$Rev:: 13            $:  Revision of last commit
$Author:: harry      $:  Author of last commit
$Date:: 2006-03-15 0#$:  Date of last commit
```
固定长度的关键字替换在以下场景非常方便: (1) 文件把数据放在长度固定 的字段里; (2) 除了格式的本地应用程序外, 其他程序难以修改某些数据字段 的存放大小. 当然, 如果涉及到二进制文件格式, 用户必须非常小心, 关键字替换 (无论是长度是否固定) 不能破坏格式的完整性. 虽然这听起来很容易, 但是对于 现在流行的大多数二进制格式而言, 实际做起来可能会非常困难, 绝不是稍微用 点心就能对付过去的.

## 稀疏目录

默认情况下, 大多数 Subversion 操作在处理目录时会采用递归的方式, 比如说, svn checkout 会检出仓库指定区域内的所有文件与目录. Subversion 1.5 引入了一个新特性: 稀疏目录 (sparse directories, 或 浅检出 (shallow checkouts)). 和完整的递归 操作相比, 新特性允许用户更加轻浅的检出工作副本—或工作副本的一部分, 以后仍然还能访问到原来未被检出的文件与子目录.

举个例子, 假设我们有一个仓库, 仓库中存放的是拥有宠物的家庭成员 (这个 例子确实有点奇怪), 普通的 svn checkout 操作会得到 一个具体整棵目录树的工作副本:

```
$ svn checkout file:///var/svn/repos mom
A    mom/son
A    mom/son/grandson
A    mom/daughter
A    mom/daughter/granddaughter1
A    mom/daughter/granddaughter1/bunny1.txt
A    mom/daughter/granddaughter1/bunny2.txt
A    mom/daughter/granddaughter2
A    mom/daughter/fishie.txt
A    mom/kitty1.txt
A    mom/doggie1.txt
Checked out revision 1.
$
```
现在我们再次执行检出操作, 不过这次要求 Subversion 只检出最上层的目 录, 不包括其中的文件与子目录:

```
$ svn checkout file:///var/svn/repos mom-empty --depth empty
Checked out revision 1
$
```
注意我们这次给命令 svn checkout 加了一个选项 --depth. 很多子命令都支持这个选项, 选项的意义类似于 --non-recursive (-N) 和 --recursive (-R). 实际上, Subversion 希望选项 --depth 最终能超过并替换掉这两个旧选项. 对 新手来说, --depth 拓宽了用户能够指定的操作深度, 增加了 一些原来不支持 (或支持地不一致) 的深度. 下面是用户可以使用的几种深度值:

* `--depth empty` 只包含操作的直接目标, 不包括其中的文件或子目录.
* `--depth files` 只包含操作的直接目标及其中的直接子文件.
* `--depth immediates` 包括操作的目标自身, 及它的直接子文件与直接子目录, 子目录为空.
* `--depth infinity` 包括目标自身, 及它的所有子文件与子目录, 子目录的子文件与 子目录, 等等.

当然, 如果仅仅是把两个选项合并成一个选项, 那就没必要花费整整一节的笔墨 介绍它, 幸运的是远不止选项合并这么简单. 深度的概念不仅延伸到 Subversion 客户端执行的操作, 同时还描述了工作副本的 周围深度 (ambient depth), 它是工作副本为项目记录的深度. 深度的关键之处在于它是 "粘着" (sticky) 的, 工作副本记住了用户为每一个项目 指定的深度, 在用户显式地修改之前, 项目的深度不会发生变化. 默认情况下, 不管文件的深度设置是什么样的, Subversion 的命令只会操作工作副本中已有 的项目.

前面的两个例子演示的深度值 infinity ( svn checkout 的默认行为) 和 empty 的效果, 现在看一下其他深度的例子:

```
$ svn checkout file:///var/svn/repos mom-files --depth files
A    mom-files/kitty1.txt
A    mom-files/doggie1.txt
Checked out revision 1.
$ svn checkout file:///var/svn/repos mom-immediates --depth immediates
A    mom-immediates/son
A    mom-immediates/daughter
A    mom-immediates/kitty1.txt
A    mom-immediates/doggie1.txt
Checked out revision 1.
$
```
和 empty 相比, 这些深度会得到更多的内容, 但和 infinity 相比, 会得到更少的内容.

我们已经介绍了 svn checkout 如何利用选项 --depth, 但读者会看到除了 checkout, 还有很多子命令也支持 --depth. 在这些命令中, 指定深度 将操作的作用域限制在某一层次上, 非常类似老选项 --non-recursive 和 --recursive 的行为. 这就意味着当我们操作 一个处在某个深度上的工作副本时, 可以执行一个深度更浅的操作. 实际上, 我 们可以更一般地说: 对于一个给定的, 处于任意的周围深度 (深度可以是混合的) 的工作副本, 和一个指定了操作深度 (或使用默认值) 的 Subversion 命令, 命令 将保持工作副本的周围深度不变, 同时将操作的作用域限制在所给定 (或默认的) 的操作深度上.

除了选项 --depth, 命令 svn update 和 svn switch 还支持第二种与深度有关的选项 --set-depth, 它可以修改工作副本中项目的粘着深度. 现在看 一下如何使用 svn update --set-depth NEW-DEPTH TARGET, 把原来深度为 empty 的工作副本逐渐加深:

```
$ svn update --set-depth files mom-empty
Updating 'mom-empty':
A    mom-empty/kittie1.txt
A    mom-empty/doggie1.txt
Updated to revision 1.
$ svn update --set-depth immediates mom-empty
Updating 'mom-empty':
A    mom-empty/son
A    mom-empty/daughter
Updated to revision 1.
$ svn update --set-depth infinity mom-empty
Updating 'mom-empty':
A    mom-empty/son/grandson
A    mom-empty/daughter/granddaughter1
A    mom-empty/daughter/granddaughter1/bunny1.txt
A    mom-empty/daughter/granddaughter1/bunny2.txt
A    mom-empty/daughter/granddaughter2
A    mom-empty/daughter/fishie1.txt
Updated to revision 1.
$
```
随着深度的不断加深, 每次更新, 仓库都会给我们传来更多的数据.

在上面的例子里, 我们都是在工作副本的根目录执行操作, 改变周围深度, 其 实我们可以独立地修改工作副本的 任意 子目录的周围 深度. 认真使用这项特性就可以在工作副本中只保留感兴趣的部分, 而忽略那些 不重要的部分 (所以称为 “稀疏” 目录), 下面的例子展示了典型 的用法:

```
$ rm -rf mom-empty
$ svn checkout file:///var/svn/repos mom-empty --depth empty
Checked out revision 1.
$ svn update --set-depth empty mom-empty/son
Updating 'mom-empty/son':
A    mom-empty/son
Updated to revision 1.
$ svn update --set-depth empty mom-empty/daughter
Updating 'mom-empty/daughter':
A    mom-empty/daughter
Updated to revision 1.
$ svn update --set-depth infinity mom-empty/daughter/granddaughter1
Updating 'mom-empty/daughter/granddaughter1':
A    mom-empty/daughter/granddaughter1
A    mom-empty/daughter/granddaughter1/bunny1.txt
A    mom-empty/daughter/granddaughter1/bunny2.txt
Updated to revision 1.
$
```
幸运的是, 在一个工作副本里出现如此复杂的周围深度并不会使用户与工作 副本的交互也变得复杂. 用户仍然可以像以往那样修改文件, 显示修改, 撤消或 提交修改, 而不用给相关命令提供新的选项 (包括 --depth 和 --set-depth). 当没有指定深度时, svn update 也能正常工作—命令根据各个项目的粒着深度更新工作副本里 已有的文件和目录.

读者心里可能在想 “那么, 我什么时候会用到稀疏目录呢?” 用到稀疏目录的一种场景是仓库的布局比较特殊, 尤其是许多相关的项目模块都 在同一个仓库中分别占据一个单独的目录 (例如 trunk/project1 , trunk/project2, trunk/project3 等), 但是用户可能只关心其中的部分模块— 比如说项目的主要模块及其依赖模块. 用户可以分别检出他所关心的各个模块的 工作副本, 但是这些工作副本之间是分离的, 如果想同时对它们执行同一个操作 就会很麻烦, 必须多次切换目录. 另一种选择是利用稀疏目录特性, 检出一个只 包含了感兴趣的模块的工作副本. 首先为模块的公共父目录检出一个深度为 empty 的工作副本, 然后按照深度 infinity 更新感兴趣的模块目录, 就像我们在上一个例子中展示的那样.

浅检出的原始实现 (Subversion 1.5) 就已经很不错了, 但是它不能缩减 工作副本项目的深度, Subversion 1.6 解决了这个问题. 比如说在一个深度 原来是 infinity 的工作副本里执行 svn update --set-depth empty, 工作副本就会删除除了顶层目录 外的所有文件与目录 [26] Subversion 1.6 还 为选项 --set-depth 引入的一个新的值: exclude . 如果给命令 svn update 带上选项 --set-depth exclude 会造成被更新的目标从工作副本中完全 删除—如果目标是一个目录, 那么目录也会被完全删除, 而不是留下一个 空目录. 如果工作副本中用户想保留的东西要比不想保留的东西多, 那 --set-depth exclude 就能提供很大的方便.

考虑一个包含了几百个子目录的目录, 用户想要从工作副本中忽略其中一个 子目录, 如果是用 “增量” 的方法得到稀疏目录, 首先先检出一 个深度为 empty 的工作副本, 然后显式地把每一个子目录 的深度设置成 infinity (使用 svn update --set-depth infinity), 除了那个用户 不感兴趣的子目录.

```
$ svn checkout http://svn.example.com/repos/many-dirs --depth empty
…
$ svn update --set-depth infinity many-dirs/wanted-dir-1
…
$ svn update --set-depth infinity many-dirs/wanted-dir-2
…
$ svn update --set-depth infinity many-dirs/wanted-dir-3
…
### and so on, and so on, ...
```

这可能会非常枯燥, 另一个问题是如果有人提交了一个新的子目录, 当 你更新工作副本时将看不到这个新的子目录, 这应该不是你想要的效果.

从 Subversion 1.6 开始, 你有了另一种选择. 首先检出一个完整的目录, 然后在不兴趣的目录上执行 svn update --set-depth exclude

```
$ svn checkout http://svn.example.com/repos/many-dirs
…
$ svn update --set-depth exclude many-dirs/unwanted-dir
D         many-dirs/unwanted-dir
$
```
和第一种方法相比, 使用第二种方法后在工作副本里留下的数据是相同的, 但是如果有新的子目录被提交到仓库中, 更新工作副本时仍然可以看到. 第二种 方法的缺点是一开始要检出后来不用的子目录, 如果子目录过于庞大, 大到磁盘 无法容纳 (可能这就是用户不想把它检出到工作副本里的原因).

如果出现这种情况, 你可能需要一个折衷的方法. 首先, 使用 --depth immediates 检出顶层目录, 然后用 svn update --set-depth exclude 排除不感兴趣的子目录, 最后, 把剩下的子目录的深度设置成 infinity, 因为子目录都已 经出现在本地了, 所以应该会容易一点.

```
$ svn checkout http://svn.example.com/repos/many-dirs --depth immediates
…
$ svn update --set-depth exclude many-dirs/unwanted-dir
D         many-dirs/unwanted-dir
$ svn update --set-depth infinity many-dirs/*
…
$
```

再说一次, 这种方法得到的工作副本里的数据和前两种方法完全相同, 当有 新的文件或目录提交到顶层目录时, 更新操作按深度 empty 把文件或目录更新到本地, 接下来你可以决定针对新出现的项目应该采取什么 操作: 是把深度扩展到 infinity, 还是把它排除.

## 锁

Subversion 的数据合并算法与 复制-修改-合并 模型之间的关系就像水和 船: 水能载舟, 亦能覆舟—尤其是当 Subversion 尝试解决冲突时, 合并 算法的表现至关重要. Subversion 自身只提供了一种合并算法: 三路差异比较算 法的智能足够在行的级别上处理数据. 作为补充, Subversion 允许用户指定外部 的差异比较工具 (在 the section called “External diff3” 和 the section called “External merge” 介绍), 这些外 部工具可能比 Subversion 工作得更好, 比如在单词或字符的级别上比较差异. 但是这些工具和 Subversion 的算法通常只能处理文本文件, 在面对非文本文件 时, 现实就残酷多了. 如果用户无法找到支持非文本文件合并的工具, 复制-修改-合并 模型就不再适用.

介绍一个现实生活中可能会遇到的例子. Harry 和 Sally 是同一个项目的 图片设计师, 为汽车保险部门设计一款海报. 海报的中心是一辆汽车, 海报的格式 是 PNG. 海报的布局已经基本确定, Harry 和 Sally 将一辆 1967 年淡蓝色 Ford Mustang 照片放在海报中央, 车的左前侧保险杠有一点凹陷.

项目计划有所改动, 导致车身的颜色需要修改, 于是 Sally 把工作副本更 新到 HEAD, 打开图片编辑软件, 将车身的颜色改成樱桃红. 同时, Harry 觉得车的毁坏程度应该更严重一些, 这样效果更好, 于是他也把自己 的工作副本更新到 HEAD, 在车挡风玻璃上增加了一些裂痕. 就在 Harry 提交修改后, Sally 也提交了自己的修改, 显然, Subversion 会拒绝 Sally 的提交.

现在麻烦来了. 如果 Harry 和 Sally 编辑的是文本文件, 此时 Sally 只 要更新工作副本, 然后就可以再次尝试提交, 最差的情况不过是两人都修改了文件 的同一区域, 而 Sally 必须手工地解决冲突. 但海报不是文本文件, 它是二进制 的图片, 没有哪一款软件可以聪明到能够把两张图片合并成一张, 最终得到一辆 樱桃红的, 挡风玻璃上有裂痕的汽车.

如果 Harry 和 Sally 是串行地修改图片, 那事情就会顺利很多—比如 Sally 修改车身颜色并提交后, Harry 再去添加裂痕, 或者是 Sally 等到 Harry 添加裂 痕后再去修改车身颜色. the section called “复制-修改-合并 解决方案” 已经说过, 如果 Harry 和 Sally 之间进行了充分的沟通, 这种问题大部分都可 以迎刃而解. 但是版本控制系统也是一种沟通的形式, 由软件来保证工作的串行 化并不是一件坏事, 反而效果更好, 效率更高. 正是基于这点考虑, Subversion 实现了 加锁-修改-解锁 模型. Subversion 的 锁定 特性和其他版本控制系统的 “保留检出” 比较类似.

Subversion 的锁定特性是为了最大程度地减少时间和精力的浪费. 允许用户 独占地修改仓库中的文件, 保证了用户在不支持合并的修改上所花费的精力不会 被浪费—他的修改总能提交成功. 并且, Subversion 把对象正在被锁定的 事实告诉给了其他用户, 其他用户就可以知道该对象正在被修改, 也就不会把时 间浪费在无法成功提交与合并的修改上.

当我们谈到 Subversion 的锁定特性时, 实际上说的是多种不同行为的集合, 包括锁定文件的的能力 [27] (获得独占修改文件的权利), 解锁一个文件 (放弃独占修改 文件的权利), 查看哪些文件被哪些用户锁定, 为锁定的文件添加注释 (强烈建议) 等, 所有的这些都会在本节进行详细介绍.

### 创建锁

在 Subversion 仓库里, 一个 锁 (lock ) 就是一段元数据, 它赋予了一个用户独占修改文件的权利. 仓库 负责管理锁, 具体来说就是锁的创建, 实施和删除. 如果有一个提交试图修改或 删除被锁定了的文件 (或删除文件的某个父目录), 仓库就会要求客户端提供 2 项信息—一是执行提交操作的客户端已被授权为锁的所有者, 二是提供了 锁令牌, 表明客户端知道它用的是哪一个锁.

为了演示锁的创建, 我们再以海报设计作为例子. Harry 决定修改一个 JPEG 图片, 为了防止其他用户在他完成修改之前向该文件提交修改, 他使用命令 svn lock 锁定了仓库中的文件:

```
$ svn lock banana.jpg -m "Editing file for tomorrow's release."
'banana.jpg' locked by user 'harry'.
$
```
上面的例子展示了一些新东西. 首先, Harry 向命令 svn lock 传递了选项 --message (-m), 和命令 svn commit 类似, svn lock 支持注释—借助选项 --message (-m) 或 --file (-F)—注释描述了锁定文件的原因. 然而, 和 svn commit 不同的是 svn lock 不 会通过启动文本编辑器来要求用户输入注释, 注释是可选的, 但是为了更好地 与其他用户沟通, 建议输入注释.

第二, 尝试加锁成功了, 这就是说文件之前未被锁定, 而且 Harry 工作副本 里的文件是最新的. 如果 Harry 工作副本里的文件是过时了的, 仓库将会拒绝 加锁请求, 要求 Harry 执行 svn update 并重新执行加 锁命令. 如果文件已经处于加锁状态, 加锁命令也会失败.

如果加锁成功, svn lock 会输出确认信息, 从现在开始, 文件已经被锁定的事实会体现在 svn status 和 svn info 的输出信息里.

```
$ svn status
     K  banana.jpg

$ svn info banana.jpg
Path: banana.jpg
Name: banana.jpg
Working Copy Root Path: /home/harry/project
URL: http://svn.example.com/repos/project/banana.jpg
Relative URL: ^/banana.jpg
Repository Root: http://svn.example.com/repos/project
Repository UUID: edb2f264-5ef2-0310-a47a-87b0ce17a8ec
Revision: 2198
Node Kind: file
Schedule: normal
Last Changed Author: frank
Last Changed Rev: 1950
Last Changed Date: 2006-03-15 12:43:04 -0600 (Wed, 15 Mar 2006)
Text Last Updated: 2006-06-08 19:23:07 -0500 (Thu, 08 Jun 2006)
Properties Last Updated: 2006-06-08 19:23:07 -0500 (Thu, 08 Jun 2006)
Checksum: 3b110d3b10638f5d1f4fe0f436a5a2a5
Lock Token: opaquelocktoken:0c0f600b-88f9-0310-9e48-355b44d4a58e
Lock Owner: harry
Lock Created: 2006-06-14 17:20:31 -0500 (Wed, 14 Jun 2006)
Lock Comment (1 line):
Editing file for tomorrow's release.

$
```
svn info 在执行时不会与仓库通信, 但是它仍然可 以显示锁令牌, 说明了一个很重要的信息: 它们被缓存在工作副本里. 锁令牌 的存在非常重要, 它向工作副本提供了使用锁的授权. 并且, svn status 在文件名的旁边显示一个 K (locKed 的缩写), 表示该文件存在锁令牌.

因为 Harry 已经锁定了文件 banana.jpg, 所以 Sally 不能提交和 banana.jpg 有关的修改:

```
$ svn delete banana.jpg
D         banana.jpg
$ svn commit -m "Delete useless file."
Deleting       banana.jpg
svn: E175002: Commit failed (details follow):
svn: E175002: Server sent unexpected return value (423 Locked) in response to
DELETE request for '/repos/project/!svn/wrk/64bad3a9-96f9-0310-818a-df4224ddc
35d/banana.jpg'
$
```
修改完香蕉的黄色阴影后, Harry 可以向仓库提交修改, 这是因为他被授 权为锁的拥有者, 而且工作副本包含了正确的锁令牌:

```
$ svn status
M    K  banana.jpg
$ svn commit -m "Make banana more yellow"
Sending        banana.jpg
Transmitting file data .
Committed revision 2201.
$ svn status
$
```
注意提交完成后, svn status 显示锁令牌不再出现 在工作副本里, 这是 svn commit 的标准行为— 它搜索工作副本 (如果提供了目标列表, 则搜索该列表) 的本地修改, 并将所 有遇到的锁令牌作为提交事务的一部分发送给服务器, 如果提交成功, 仓库中 所有涉及到的锁都会被释放—即使是未被提交的文件上的锁 也会被释放. 这是为了防止粗心的用户持锁时间过长. 如果 Harry 随意地把目录 images 下的 30 个文件都锁定了 (因为他 不确定哪些文件需要修改), 而他只修改了其中 4 个文件, 当他执行完 svn commit images 后, 所有 30 个文件的锁都会被 释放.

为 svn commit 添加选项 --no-unlock 就不会在提交成功后自动释放锁, 适用选项的场景是用户需要多次 提交修改. 你可以通过运行时配置选项 no-unlock (见 the section called “Runtime Configuration Area”) 把不自动释放锁设置成默认行为.

当然, 锁定文件后并不要求一定要向该文件提交修改才能释放锁, 用户可以在 任何时候用命令 svn unlock 释放文件上的锁:

```
$ svn unlock banana.c
'banana.c' unlocked.
```

### 发现锁

如果由于其他用户锁定了文件而导致提交失败, 获取有关锁的信息非常方便, 最简单的方式是执行 svn status -u:

```
$ svn status -u
M               23   bar.c
M    O          32   raisin.jpg
        *       72   foo.h
Status against revision:     105
$
```
在这个例子里, Sally 不仅可以看到 foo.h 是过时了的, 而且他打算提交的两个文件中, 有一个在仓库中是被锁定了的. 字符 O 表示 “其他” (“Other”), 意思是说 文件被其他用户锁定了, 如果 Sally 试图提交, raisin.jpg 上的锁会阻止提交成功. Sally 想知道是 谁, 在什么时候, 因为什么原因锁定了文件, svn info 可以 回答他的问题:

```
$ svn info ^/raisin.jpg
Path: raisin.jpg
Name: raisin.jpg
URL: http://svn.example.com/repos/project/raisin.jpg
Relative URL: ^/raisin.jpg
Repository Root: http://svn.example.com/repos/project
Repository UUID: edb2f264-5ef2-0310-a47a-87b0ce17a8ec
Revision: 105
Node Kind: file
Last Changed Author: sally
Last Changed Rev: 32
Last Changed Date: 2006-01-25 12:43:04 -0600 (Sun, 25 Jan 2006)
Lock Token: opaquelocktoken:fc2b4dee-98f9-0310-abf3-653ff3226e6b
Lock Owner: harry
Lock Created: 2006-02-16 13:29:18 -0500 (Thu, 16 Feb 2006)
Lock Comment (1 line):
Need to make a quick tweak to this image.
$
```
svn info 除了可以检查工作副本里的项目外, 也可以 检查仓库里的项目. 如果传递给 svn info 的参数是一个 工作副本路径, 那么缓存在工作副本里的所有信息都会显示出来; 只要显示的 信息中提到了锁, 那就说明工作副本持有一个锁令牌 (如果文件是被其他用户 或者是在另一个工作副本里锁定的, 那么在一个工作副本路径上执行 svn info 将不会显示关于锁的任何信息). 如果传递给 svn info 的是一个 URL, 输出的信息反映了仓库中的 项目的最新版, 信息中提到关于锁的任何信息都是在描述项目的当前加锁情况.

在我们的例子里, Sally 可以看到 Harry 在 2 月 16 日锁定了文件 raisin.jpg, 原因是 “Need to make a quick tweak to this image”. 现在已经 6 月了, Sally 怀疑 Harry 忘记给文件解锁, 她可能会打电话给 Harry, 向他抱怨, 让他马上释放锁. 如 果联系不到 Harry, 她可能会强行地破坏锁, 或者让管理员来帮她解决.


### 破坏与窃取锁

锁并非是不可侵犯的—在 Subversion 的默认配置状态下, 除了创建锁的 用户可以释放锁之外, 任意一个用户也可以释放锁. 如果释放锁的用户不是锁 的创建者, 我们把这种行为叫作 破坏锁 (breaking the lock).

对于管理员来说, 破坏锁非常简单. 命令 svnlook 和 svnadmin 可以直接从仓库中显示与移除锁 (关于 svnlook 和 svnadmin 的更多信息, 见 the section called “管理员工具箱”).

```
$ svnadmin lslocks /var/svn/repos
Path: /project2/images/banana.jpg
UUID Token: opaquelocktoken:c32b4d88-e8fb-2310-abb3-153ff1236923
Owner: frank
Created: 2006-06-15 13:29:18 -0500 (Thu, 15 Jun 2006)
Expires:
Comment (1 line):
Still improving the yellow color.

Path: /project/raisin.jpg
UUID Token: opaquelocktoken:fc2b4dee-98f9-0310-abf3-653ff3226e6b
Owner: harry
Created: 2006-02-16 13:29:18 -0500 (Thu, 16 Feb 2006)
Expires:
Comment (1 line):
Need to make a quick tweak to this image.

$ svnadmin rmlocks /var/svn/repos /project/raisin.jpg
Removed lock on '/project/raisin.jpg'.
$
```
Subversion 还允许用户通过网络破坏其他用户的锁, 为了破坏 Harry 设置 在 raisin.jpg 上的锁, Sally 要给 svn unlock 加上选项 --force:

```
$ svn status -u
M               23   bar.c
M    O          32   raisin.jpg
        *       72   foo.h
Status against revision:     105
$ svn unlock raisin.jpg
svn: E195013: 'raisin.jpg' is not locked in this working copy
$ svn info raisin.jpg | grep ^URL
URL: http://svn.example.com/repos/project/raisin.jpg
$ svn unlock http://svn.example.com/repos/project/raisin.jpg
svn: warning: W160039: Unlock failed on 'raisin.jpg' (403 Forbidden)
$ svn unlock --force http://svn.example.com/repos/project/raisin.jpg
'raisin.jpg' unlocked.
$
```
在上面的例子里, Sally 第一次尝试解锁失败了, 因为她直接在工作副本 的 raisin.jpg 上执行 svn unlock, 而她的工作副本里并没有锁令牌. 为了直接从仓库中删除锁, 她需要向 svn unlock 传递一个 URL 参数. 增加 URL 参数后的第 一次尝试失败了, 因为她没有被授权为锁的所有者 (而且她也没有锁令牌). 但 是增加了选项 --force 后, 锁成功的被打开 (破坏) 了.

仅仅把锁破坏掉可能还不够. Sally 除了要打开 Harry 忘记打开的锁之外, 她 还想重新锁定文件, 以便自己对文件进行编辑. 她可以先用带上选项 --force 的 svn unlock 把锁打开, 然后再 用 svn lock 锁定文件. 但是在两个命令之间可能会有 其他用户锁定了文件. 更简单的做法是 窃取 (steal) 锁, 它是把锁的破坏与重新加锁合并成一个 原子操作, 具体的做法是给 svn lock 加上选项 --force:

```
$ svn lock raisin.jpg
svn: warning: W160035: Path '/project/raisin.jpg' is already locked by user 'h
arry' in filesystem '/var/svn/repos/db'
$ svn lock --force raisin.jpg
'raisin.jpg' locked by user 'sally'.
$
```
无论锁是被破坏还是被窃取, Harry 都会感到惊讶. Harry 的工作副本仍然包 含原来的锁令牌, 但是锁却不存在了, 此时把锁令牌称为 失效的 (defunct), 锁令牌对应的锁要么被 破坏 (不在仓库里), 要么被窃取 (被另一把不同的锁替换掉). 不管是哪一种 情况, Harry 都可以用 svn status 查看详情:

```
$ svn status
     K  raisin.jpg
$ svn status -u
     B          32   raisin.jpg
Status against revision:     105
$ svn update
Updating '.':
  B  raisin.jpg
Updated to revision 105.
$ svn status
$
```

如果仓库的锁被破坏了, svn status --show-updates (-u) 会在文件的旁边显示字符 B (Broken). 如果有一把新锁出现在原来的位置上, 显示的就是字符 T (sTolen). 最后, svn update 会从工作副本中移除所有的失效锁.

### 锁通信
我们已经介绍了如何使用 svn lock 和 svn unlock 完成锁的创建, 释放, 破坏与窃取. 锁实现了文件 的串行提交, 但是我们应该如何防止浪费时间?

比如说, Harry 锁定了一个图片文件, 然后开始编辑. 同时在几英里之外, Sally 也想编辑同一个文件, 她忘了执行 svn status -u, 所以她完全不知道 Harry 已经锁定了 她要编辑的文件. 她花了几个小时完成了图片的修改, 当她试图提交修改时, 发现文件被锁定或者工作副本里的文件过时了. 无论如何, 她的修改无法与 Harry 的修改合并, 两人中必须有一个人要放弃他的工作成果.

Subversion 的解决办法是提供了一种机制, 这种机制会提醒用户在开始 修改文件之前, 要先锁定文件, 这种机制是一个特殊的属性 svn:needs-lock. 如果文件设置了该属性 (属性值并不重要), Subversion 将试图使用文件系统的权限把文件设置成只读—除非用户显式 地锁定了文件. 如果提供了锁令牌 (svn lock 的运行结果), 文件的权限就变成可读写, 如果锁被释放了, 文件再次变成只读.

如果图片文件设置了属性 svn:needs-lock, 当 Sally 打开并开始修改图片时就会注意到有些地方不对劲: 很多程序在以读 写方式打开文件时, 如果发现文件是只读的, 将会向用户发出警告, 并阻止用户 向只读文件保存修改. 这将会提醒 Sally 应该在修改之前先锁定文件, 到那时 她就会发现锁已经预先被别人锁定了:

```
$ /usr/local/bin/gimp raisin.jpg
gimp: error: file is read-only!
$ ls -l raisin.jpg
-r--r--r--   1 sally   sally   215589 Jun  8 19:23 raisin.jpg
$ svn lock raisin.jpg
svn: warning: W160035: Path '/project/raisin.jpg' is already locked by user 'h
arry' in filesystem '/var/svn/repos/db'
$ svn info http://svn.example.com/repos/project/raisin.jpg | grep Lock
Lock Token: opaquelocktoken:fc2b4dee-98f9-0310-abf3-653ff3226e6b
Lock Owner: harry
Lock Created: 2006-06-08 07:29:18 -0500 (Thu, 08 June 2006)
Lock Comment (1 line):
Making some tweaks.  Locking for the next two hours.
$
```

注意 svn:needs-lock 是一个通信工具, 与加锁系统 独立工作. 换句话说, 无论是否设置了这个属性, 文件都可以被锁定, 相反, 设置了这个属性, 仓库也不会要求在提交时必须提供锁.

不幸的是, 这种机制并非毫无缺点. 即使文件设置了属性 svn:needs-lock, 只读提醒也可能不会起作用. 有时候应用 程序不够规范, 会 “劫持” 只读文件, 然后悄无声息地允许用户修改并 保存文件. Subversion 对这种情况无能为力—目前为止还没有什么方法可以 完全替代人与人之间的交流[28]

## 外部定义

有时候, 构造一个由多个不同的检出所组成的工作副本是很有用的, 比如说, 用户可能想把多个来自不同位置的子目录放到一个目录里, 这些子目录甚至来自不 同的仓库. 用户当然可以手工实现—用 svn checkout 创建出嵌套的工作副本结构. 但是如果每个用户都有这种需求, 那么所有的用户 都得自己手工构造.

幸运的是, Subversion 支持 外部定义 ( externals definitions), 外部定义是一个本地目录到仓库目录 URL 的映射. 用户使用属性 svn:externals 批量地声明外 部定义, 创建或修改属性的命令是 svn propset 或 svn propedit (见 the section called “操作属性”). 属性 svn:externals 可以设置在任意一个被版本控制的目录上, 属性的值描述了外部 仓库的位置, 以及检出到本地时得到的本地目录.

svn:externals 的方便之处是一旦目录设置了该属性, 所有检出该目录的用户都会受益. 换句话说, 如果有一个用户已经用外部定义 构造好了一个嵌套的工作副本结构, 其他用户就不用再重新做一遍— 当原始的工作副本检出完毕后, Subversion 还会自动检出外部的工作副本.

svn:externals 是版本化的属性, 如果用户需要 修改一个外部定义, 使用普通的属性修改子命令即可. 如果提交了属性 svn:externals 的修改, 下一次执行 svn update 时, Subversion 将会根据修改后的外部定义更新 检出的项目, 同样的事情也会发生在其他用户的工作副本里.

Subversion 1.5 之前的外部定义的格式是一个多行表格, 每一行包括子 目录 (相对于设置了属性的目录), 可选的版本号标志, 以及一个完全限定的, Subversion 仓库 URL 的绝对路径. 外部定义的一个例子是:

```
$ svn propget svn:externals calc
third-party/sounds             http://svn.example.com/repos/sounds
third-party/skins -r148        http://svn.example.com/skinproj
third-party/skins/toolkit -r21 http://svn.example.com/skin-maker
```

如果用户检出了目录 calc, Subversion 会继续检出 外部定义里的项目.

```
$ svn checkout http://svn.example.com/repos/calc
A    calc
A    calc/Makefile
A    calc/integer.c
A    calc/button.c
Checked out revision 148.

Fetching external item into calc/third-party/sounds
A    calc/third-party/sounds/ding.ogg
A    calc/third-party/sounds/dong.ogg
A    calc/third-party/sounds/clang.ogg
…
A    calc/third-party/sounds/bang.ogg
A    calc/third-party/sounds/twang.ogg
Checked out revision 14.

Fetching external item into calc/third-party/skins
…
```

从 Subversion 1.5 开始, svn:externals 开始支持一 种新的格式, 外部定义仍然是多行文本, 但某些信息的顺序与格式发生了变化. 新的语法更加贴近 svn checkout 的参数: 首先是可选的 版本号标志, 然后是外部仓库的 URL, 本地目录的相对路径. 注意, 这次我们没有 说 “完全限定的, Subversion 仓库的 URL 的绝对路径”, 这是因为 新的格式支持相对 URL 和带有挂勾版本号的 URL. 上面的例子在 Subversion 1.5 里的写法是:

```
$ svn propget svn:externals calc
      http://svn.example.com/repos/sounds third-party/sounds
-r148 http://svn.example.com/skinproj third-party/skins
-r21  http://svn.example.com/skin-maker third-party/skins/toolkit
```
带有挂勾版本号 (见 the section called “挂勾版本号与实施版本号”) 的写法是:

```
$ svn propget svn:externals calc
http://svn.example.com/repos/sounds third-party/sounds
http://svn.example.com/skinproj@148 third-party/skins
http://svn.example.com/skin-maker@21 third-party/skins/toolkit
```

对大多数仓库而言, 三种格式的外部定义的最终效果都是一样的, 它们都有 同样的好处, 也都有同样的麻烦. 因为用到了 URL 的绝对路径, 如果移动或 复制一个带有外部定义的目录, 这并不会对外部定义的检出造成影响 (虽然本地 目标子目录的绝对路径会随着目录的重命名而发生变化). 在某些情况下, 这会给 用户造成困扰, 比如说, 用户有一个名为 my-project 的顶层目录, 用户在它的其中一个子目录 (my-project/some-dir ) 上设置了外部定义, 外部定义指向的是另一个子目录 ( my-project/external-dir).

```
$ svn checkout http://svn.example.com/projects .
A    my-project
A    my-project/some-dir
A    my-project/external-dir
…
Fetching external item into 'my-project/some-dir/subdir'
Checked out external at revision 11.

Checked out revision 11.
$ svn propget svn:externals my-project/some-dir
subdir http://svn.example.com/projects/my-project/external-dir

$
```

现在用户用 svn move 重命名 my-project , 但外部定义仍然指向 my-project 的子目 录, 即使这个目录已经不存在了.

```
$ svn move -q my-project renamed-project
$ svn commit -m "Rename my-project to renamed-project."
Deleting       my-project
Adding         renamed-project

Committed revision 12.
$ svn update
Updating '.':

svn: warning: W200000: Error handling externals definition for 'renamed-projec
t/some-dir/subdir':
svn: warning: W170000: URL 'http://svn.example.com/projects/my-project/externa
l-dir' at revision 12 doesn't exist
At revision 12.
svn: E205011: Failure occurred processing one or more externals definitions
$
```

另外, 当使用绝对的 URL 路径时, 如果仓库支持多种 URL 模式, 这也会产 生问题. 比如说仓库服务器允许任意用户通过 http:// 或 https:// 访问仓库, 但只允许通过 https:// 提交修改. 如果用户的外部定义使用了 http:// 形式的 URL, 用户将无法从外部定义创建的工作副本里提交修改. 另一方面, 如果仓库服务器只支持 https:// 形式的 URL, 但客户端 只支持 http://, 那么它将无法检出外部项目. 还要注意, 如果用户重定位了工作副本 (通过命令 svn relocate), 外部定义检出的工作副本并 不会 被重定位.

在改善这些问题方面, Subversion 1.5 前进了一大步. 前面已经说过新的 外部定义支持 URL 的相对路径, Subversion 1.5 提供了多种指定相对 URL 路径 的语法.

* `../` 相对于设置了 svn:externals 的目录的 URL
* `^/` 相对于 svn:externals 所在的仓库的根 目录
* `//` 相对于设置了属性 svn:externals 的目录 的 URL 模式
* `/` 相对于 svn:externals 所在的仓库的根 URL
* `^/../REPO-NAME` 相对于和定义了 svn:externals 的仓库 处于同一个 SVNParentPath 位置下的兄弟仓库

如果把绝对的 URL 路径改成相对路径, 之前的例子就可以写成:

```
$ svn propget svn:externals calc
^/sounds third-party/sounds
/skinproj@148 third-party/skins
//svn.example.com/skin-maker@21 third-party/skins/toolkit
$
```

Subversion 1.6 为外部定义添加了两个增强功能, 首先, 利用引号和转义字 符, 外部工作副本的路径可以包含空格, 在此之前如何处理路径中的空格是一 件很麻烦的事情, 因为空格被用作外部定义的字段分隔符, 现在只需要用双引号 包裹路径, 或者用反斜杆 (\) 转义路径中会引起问题的字符. 如果外部定义的 URL 部分包含空格, 此时应该使用标准的 URL 编码表示空格.

```
$ svn propget svn:externals paint
http://svn.thirdparty.com/repos/My%20Project "My Project"
http://svn.thirdparty.com/repos/%22Quotes%20Too%22 \"Quotes\ Too\"
$
```
Subversion 1.6 还支持为文件设置外部定义. 外部文件 (file externals) 的配置方式与目录相同, 外部文件 将以版本化文件的形式出现在工作副本里.

比如说仓库中有一个文件 /trunk/bikeshed/blue.html, 现在你想把文件在版本号 40 时的版本放在 /trunk/www/ 的工作副本里, 作为 green.html.

实现这个要求的外部定义是:

```
$ svn propget svn:externals www/
^/trunk/bikeshed/blue.html@40 green.html
$ svn update
Updating '.':

Fetching external item into 'www'
E    www/green.html
Updated external to revision 40.

Update to revision 103.
$ svn status
    X   www/green.html
$
```
可以看到, 把文件抓取到工作副本里时, Subversion 在外部文件的左边显示字 符 E, 执行 svn status 时, 在外部文 件的左边显示字符 X.

使用 svn info 检查外部文件时, 可以看到外部文件 URL 与版本号:

```
$ svn info www/green.html
Path: www/green.html
Name: green.html
Working Copy Root Path: /home/harry/projects/my-project
URL: http://svn.example.com/projects/my-project/trunk/bikeshed/blue.html
Relative URL: ^/trunk/bikeshed/blue.html
Repository Root: http://svn.example.com/projects/my-project
Repository UUID: b2a368dc-7564-11de-bb2b-113435390e17
Revision: 40
Node kind: file
Schedule: normal
Last Changed Author: harry
Last Changed Rev: 40
Last Changed Date: 2009-07-20 20:38:20 +0100 (Mon, 20 Jul 2009)
Text Last Updated: 2009-07-20 23:22:36 +0100 (Mon, 20 Jul 2009)
Checksum: 01a58b04617b92492d99662c3837b33b
$
```
因为外部文件是作为版本化的文件出现在工作副本里, 它们可以被修改, 如 果引用的是版本号 HEAD 的文件, 还可以提交修改, 提交后的修改不仅会出现在 外部文件时, 还包括被引用的文件. 然而在我们的例子里, 外部文件被指定了一 个较旧的版本号, 所以无法提交成功:

```
$ svn status
M   X   www/green.html
$ svn commit -m "change the color" www/green.html
Sending        www/green.html
svn: E155011: Commit failed (details follow):
svn: E155011: File '/trunk/bikeshed/blue.html' is out of date
$
```

定义外部文件时要始终牢记这点: 如果外部定义指向的是一个特定版本号的 文件, 将无法提交外部文件的修改. 如果用户希望可以提交外部文件的修改, 就不要指定除了 HEAD 之外的其他版本号, 这与没有指定 版本号是同样的效果.

不幸的是, Subversion 对外部定义的支持仍然不够理想. 外部文件与外部 目录都还有不足之外需要完善. 比如说外部定义的本地子目录不能包含父目录指示 符 .. (例如 ../../skins/myskin). 外部文件不能引用其他仓库的文件, 不能直接对外部文件进行移动或删除 (但可被 复制), 而是应该修改 svn:externals.

或许最令人失望的是由外部定义创建的工作副本与主工作副本 (属性 svn:externals 所在的工作副本) 之间是分离的, 而且 Subversion 也只能操作不相交的工作副本. 也就是说如果你想要提交一个或多个外部工作副本 里的修改, 你只能显式地在每个外部工作副本里执行 svn commit —在主工作副本内提交并不会影响外部工作副本.

我们已经介绍了 svn:externals 旧格式的缺点, 以及 Subversion 1.5 的新格式如何改善这些缺点, 但是在使用新的格式时注意不要 引入新的问题. 举个例子, 最新的客户端仍然支持旧的外部定义格式, 1.5 版以前 的客户端却不支持新格式. 如果用户把所有的外部定义格式都更新成新格式, 那 就相当于强迫所有的用户都要把客户端更新成最新版. 同时还要注意外部定义里的 -rNNN 部分—旧格式把 它作为挂勾版本号, 而新格式把它作为实施版本号 (除非显式指定, 否则使用 HEAD 作为挂勾版本号, 挂勾版本号与实施版本号的区别见 the section called “挂勾版本号与实施版本号”).

svn checkout, svn update, svn switch 和 svn export 这些 命令在管理不同子目录内的工作副本时是分开进行的, 但 svn status 可以识别外部工作副本. svn status 为外部 工作副本所在的子目录显示字符 X, 然后递归地显示外部 工作副本内的各个项目的状态. 为子命令添加选项 --ignore-externals 将会禁止子命令处理外部定义.

## 变更列表
对开发人员来说, 同时在多个不同版本的代码上工作是一件很平常的事情, 这 不一定是因为计划有问题, 因为开发人员常常在阅读某一部分的代码时, 发现另 一部分代码的问题, 又或许是开发人员把一个大修改拆分成几个逻辑性更强的小 修改, 而这几个小修改还没有全部完成. 很多时候, 这些小修改不能完全包含在一 个模块里, 修改之间也不能安全地隔开, 修改可能有重叠, 或修改了同一样模块 的不同文件, 或修改了同一个文件的不同行.

开发人员可以采用不同的方法对这些在逻辑上分开的修改进行组织. 有的人 使用单独的工作副本保存未完成的修改, 其他人可能会创建短期的特性分支, 还 有的人会使用 diff 和 patch 来备份 与还原未提交的修改, 每一个修改都对应一个补丁文件. 每一种方法都有各自的 优缺点, 而且修改的细节会在很大程度上影响对修改进行区分的方法.

Subversion 提供了一种新方法: 变更列表 ( changelists). 变更列表基本上就是一些应用到工作副本文件上 的任意标签 (每个文件上最多只能有一个标签), 用来表示多个互相关联的文件的 共同目的, 经常使用谷歌软件的用户对此比较熟悉. 比如说 谷歌邮箱 并没有提供传统的基于文件夹 的邮件组织形式, 用户可以把任意的标签应用到邮件上, 如果有多个邮件的标签 相同, 就可以说它们是同一个组的, 查看具有类似标签的一组邮件变成了一个简单 的用户界面技巧. 很多 Web 2.0 网站也提供了类似的机制, 比如 YouTube 和 Flickr 的 “标签” (tag), 以及博文的 “类别” (categories). 旧的 “文件与 文件夹” 范式对某些应用程序来说过于刻板.

Subversion 允许用户通过向文件打标签来创建变更列表, 如果一个文件被打 上标签, 说明该文件和这个变更列表是相关的, 用户还可以删除标签, 把命令的 操作限定到具有特定标签的文件上, 具体的细节将在本节进行介绍.

### 创建与修改变更列表
命令 svn changelist 用于创建, 修改和删除变更列表, 更准确地说这个命令可以设置或清除某个特定的工作副本文件上的变更列表关 联. 当用户第一次用某个修改列表为文件打标签时, 修改列表才被创建出来; 当用户把最后一个标签从文件上移除时, 对应的修改列表被删除. 下面用一个 例子来解释这些概念.

Harry 正在解决计算器程序中数字运算过程的几个问题, 他已经修改了几 个文件:

```
$ svn status
M       integer.c
M       mathops.c
$
```
在测试的过程中, Harry 发现他的修改暴露了用户接口实现 button.c 里的一个问题, Harry 决定在另一个单独的提交中把 这个问题也解决掉. 在一个只包含了少量文件和修改的小工作副本里, Harry 可 以不依靠 Subversion 就可以对两个逻辑上不相关的修改进行组织, 但是今天 他想试用一下 Subversion 的变更列表.

Harry 先创建一个变更列表, 并关联两个已被修改的文件, 具体的做法是 用命令 svn changelist 向这两个文件分配一个任意的 变更列表名:

```
$ svn changelist math-fixes integer.c mathops.c
A [math-fixes] integer.c
A [math-fixes] mathops.c
$ svn status

--- Changelist 'math-fixes':
M       integer.c
M       mathops.c
$
```
可以看到, svn status 的输出反映了新的分组.

现在 Harry 着手修改用户接口的问题. 因为他知道将要修改哪个文件, 所 以他也向这个文件分配了一个变更列表, 不幸的是, Harry 错误地向第三个文件 分配了和前两个文件一样的变更列表:

```
$ svn changelist math-fixes button.c
A [math-fixes] button.c
$ svn status

--- Changelist 'math-fixes':
        button.c
M       integer.c
M       mathops.c
$
```
幸好 Harry 很快就发现了错误, 现在他有两个选择, 一是删除与 button.c 关联的变更列表, 然后分配一个新的变更列表:

```
$ svn changelist --remove button.c
D [math-fixes] button.c
$ svn changelist ui-fix button.c
A [ui-fix] button.c
$
```
二是直接向 button.c 分配一个新的变更列表, 此时 Subversion 会先移除 button.c 原来的变更列表:

```
$ svn changelist ui-fix button.c
D [math-fixes] button.c
A [ui-fix] button.c
$ svn status

--- Changelist 'ui-fix':
        button.c

--- Changelist 'math-fixes':
M       integer.c
M       mathops.c
$
```
现在 Harry 的工作副本里有了两个不同的变更列表, svn status 会根据它们的变更列表对输出进行分组. 虽然 Harry 还没有修改 button.c, 但 svn status 仍然 会输出与它有关的信息, 这是因为 button.c 被分配了 一个变更列表. 任何时候都可以向文件添加或删除变更列表, 无论它们是否含有 本地修改.

接下来, Harry 解决了 button.c 的用户接口问题.

```
$ svn status

--- Changelist 'ui-fix':
M       button.c

--- Changelist 'math-fixes':
M       integer.c
M       mathops.c
$
```

### 变更列表用作操作过滤器

我们在上一节看到的 svn status 对变更列表的分组 效果还不错, 但还不是很有用. 除了 svn status, 通过 选项 --changelist, 还有很多操作都会理解变更列表.

如果提供了选项 --changelist, Subversion 命令将会把 操作的作用域限定到具有特定变更列表的文件上. 假如说 Harry 想查看变更列表 math-fixes 里的文件的修改, 他可以在 svn diff 的后面显式地列出变更列表 math-fixes 的所有 文件.

```
$ svn diff integer.c mathops.c
Index: integer.c
===================================================================
--- integer.c	(revision 1157)
+++ integer.c	(working copy)
…
Index: mathops.c
===================================================================
--- mathops.c	(revision 1157)
+++ mathops.c	(working copy)
…
$
```
如果文件比较少的话还可以接受, 但是如果变更列表包含了 20 个或 30 个 文件, 那就有点麻烦了. 不过既然它们都属于同一个变更列表, 可以用变更列 表替换文件列表:

```
$ svn diff --changelist math-fixes
Index: integer.c
===================================================================
--- integer.c	(revision 1157)
+++ integer.c	(working copy)
…
Index: mathops.c
===================================================================
--- mathops.c	(revision 1157)
+++ mathops.c	(working copy)
…
$
```
准备提交时, Harry 可以再次使用选项 --changelist 把提交操作的作用域限定到具有特定变更列表的文件上. 他可以像下面这样提交 用户接口的修改:

```
$ svn commit -m "Fix a UI bug found while working on math logic." \
             --changelist ui-fix
Sending        button.c
Transmitting file data .
Committed revision 1158.
$
```
实际上 svn commit 还提供了另一个和变更列表相关 的选项: --keep-changelists. 一般情况下, 在文件提交后, 变更列表就会从文件上移除, 但是如果提供了选项 --keep-changelists , Subversion 就会把变更列表保留在提交了的文件上. 在任何一种 情况下, 提交某个变更列表的文件, 不会对其他变更列表产生影响.

```
$ svn status

--- Changelist 'math-fixes':
M       integer.c
M       mathops.c
$
```

命令 svn changelist 也支持选项 --changelist, 这允许用户方便地重命名或删除变更列表:

```
$ svn changelist math-bugs --changelist math-fixes --depth infinity .
D [math-fixes] integer.c
A [math-bugs] integer.c
D [math-fixes] mathops.c
A [math-bugs] mathops.c
$ svn changelist --remove --changelist math-bugs --depth infinity .
D [math-bugs] integer.c
D [math-bugs] mathops.c
$
```

最后, 用户可以一次指定多个 --changelist 选项, 此时受命令影响的文件将是它们的并集.

### 变更列表的限制

变更列表是组织工作副本文件的好工具, 但是它也有一些限制. 变更列表 是特定的工作副本的产物, 这就意味着变更列表不能被传送给仓库, 或与其他 用户分享. 只能在文件上分配变更列表—Subversion 目前还不支持在目录 上使用变更列表. 最后, 在工作副本的一个文件上最多只能分配一个变更列表, 如果用户发现自己需要在一个文件上分配多个变更列表, 那只能算你倒霉了.

## 网络模型
在某些情况下, 用户需要了解 Subversion 客户端如何与服务器通信. Subversion 的网络层是抽象的, 也就是说无论服务器是什么类型, Subversion 表现出的行为总是类似的. 不管是用 HTTP 协议 (http://) 与 Apache HTTP 服务器通信, 还是传统的 Subversion 协议 ( svn://), 基本网络模式都是相同的. 本节将介绍 Subversion 网络 模式的基本概念, 包括 Subversion 如何管理授权与认证.

### 请求与响应
Subversion 客户端的大部分时间都用在工作副本的管理上, 当它需要从远 程仓库获取信息时, 客户端生成并向服务器发送网络请求, 服务器再用适当的回答 响应该请求. 网络协议的细节对用户是透明的—客户端试图访问一个 URL, 根据 URL 模式, 客户端将使用某种特定的协议与服务器通信.

当服务器接收到客户端发来的请求时, 它经常会要求客户端阐明自己的身份. 服务器向客户端发送一个认证消息, 客户端提供 证书 ( credentials) 进行响应, 认证一旦完成, 服务器便 向客户端返回它所请求的信息. 这与 CVS 系统不同, CVS 系统的客户端先向服 务器提供证书 (“登录”), 然后再发送请求. 而在 Subversion 中, 服务器在适当的时候向客户端索要证书, 在此之前客户端不会主动向服务 器发送证书, 这样的话某些操作就更加方便. 比如说如果服务器被配置成允许 任何用户读取仓库, 当客户端试图检出工作副本时 (svn checkout ), 服务器将不会要求客户端提供证书.

如果客户端发起的请求将会产生一个新的版本号 (例如 svn commit ), Subversion 就使用请求中的, 经过认证的用户名作为新的版本号 的作者, 具体来说就是把经过认证的用户名作为新版本号的 svn:author 属性值 (见 the section called “Subversion 的保留属性”). 如果客户端未经过认证 (也就 是说服务器没有向客户端发送认证请求), 新版本号的 svn:author 属性值将为空.

### 客户端证书
很多 Subversion 服务器都会要求认证. 有时候匿名的读操作是允许的, 但是写操作必须提供得到授权, 还有些服务器要求读写都需要认证. 不同的 Subversion 服务器选项支持不同的认证协议, 但是从用户的视角来看, 可以 把认证简单地理解为用户名与密码. Subversion 客户端提供了几种不同的方法 来检索和存放用户的认证证书, 包括交互性地提示用户输入用户名与密码, 以及 存放在磁盘上的加密或未加密过的数据缓存.

对安全比较敏感的读者可能在想 “在磁盘上缓存密码? 这可是个 馊主意, 千万不要这么干!” 不用担心—并没有听起来的这么 糟糕. 下面将介绍 Subversion 使用的几种证书缓存类型, 什么时候用到它们, 以及如何禁止它们的全部或部分功能.

#### 缓存证书

Subversion 提供了一种方法, 用于避免用户每次都要输入用户名与密码. 在默认情况下, 每当客户端成功地响应服务器的认证请求时, 认证证书都会 被缓存到磁盘上, 并把服务器的主机名, 端口与认证域的组合作为键值. 这个 缓存在将来会被自动查阅, 这就避免了用户再次输入认证证书. 如果在缓存中 没有找到合适的证书, 或者是缓存的证书认证失败, 此时客户端就会提示用户 输入用户名与密码.

Subversion 开发人员承认在磁盘上缓存认证证书有可能成为安全隐患, 为了解决这个问题, Subversion 会利用操作系统环境, 把信息泄漏的风险 降到最低.

* 在 Windows 操作系统, Subversion 客户端把密码存放在 %APPDATA%/Subversion/auth/ 目录内. 在 Windows 2000 及之后的系统里, 磁盘上的密码会使用标准的 Windows 加密服务进行加密. 因为密钥由 Windows 管理, 且绑定到用户个人的 登录证书, 所以只有用户才能解密缓存的密码. (如果用户的 Windows 帐户密码被管理员重置, 那么所有缓存的密码都不能再被解密, 此时 Subversion 就认为缓存密码不存在, 在需要时重新提示用户输入.)
* 类似的, 在 Mac OS X 系统中, Subversion 用登录名作为键值存放 所有仓库的密码 (由 keychain 服务进行管理), 键值由登录密码进行 保护. 用户可以施加额外的策略, 例如每当 Subversion 要使用密码时, 就要求用户输入帐户密码.
* 类 Unix 系统没有标准的 “keychain” 服务, 但 Subversion 仍然知道如何用 “GNOME Keyring”, “ KDE Wallet” 和 “GnuPG Agent” 服务安全地 存放密码. 把未加密的密码存放在 ~/.subversion/auth/ 之前, Subversion 会询问用户是否要这么做. 注意缓存 区 auth/ 仍然受到权限的保护, 只有用户 (目录的所有者) 才能读取其中的数据. 操作系统的文件权限保护避免了密码 被系统中的其他非管理员用户看到, 当然前提是其他用户不能直接接触 存储设备或备份.

当然, 这些机制并不能完全解决问题, 对于那些为了追求安全而不惜牺牲 便利的用户来说, Subversion 提供了多种方式用于禁止证书缓存.

#### 禁止密码缓存

用户在执行一个要求认证的操作时, Subversion 默认把密码加密后缓存 在本地, 在某些操作系统中, Subversion 可能无法进行加密, 在这种情况 下 Subversion 将会询问用户是否以明文地方式缓存证书:

```
$ svn checkout https://host.example.com:443/svn/private-repo
-----------------------------------------------------------------------
ATTENTION!  Your password for authentication realm:

   <https://host.example.com:443> Subversion Repository

can only be stored to disk unencrypted!  You are advised to configure
your system so that Subversion can store passwords encrypted, if
possible.  See the documentation for details.

You can avoid future appearances of this warning by setting the value
of the 'store-plaintext-passwords' option to either 'yes' or 'no' in
'/tmp/servers'.
-----------------------------------------------------------------------
Store password unencrypted (yes/no)?
```

如果用户贪图方便, 不想每次都输入密码, 那就输入 yes . 如果用户担心以明文的方式缓存密码不太安全, 而且不想每次 都被询问是否要缓存密码, 你可以永久地禁止密码明文缓存.


为了永久地禁止以明文方式缓存密码, 在本地配置文件 servers 的 [global] 部分添加一行 store-plaintext-passwords. 为了对特定的服务器 禁止明文密码缓存, 在配置文件 servers 的适当 位置添加同样的一行 (具体的细节见 Chapter 7, Customizing Your Subversion Experience 的 the section called “Runtime Configuration Options”).

为了禁止特定的 Subversion 命令缓存密码, 向该命令添加选项 --no-auth-cache. 为了永久地禁止缓存, 在本地的 Subversion 配置文件中添加一行 store-passwords = no.

#### 删除已缓存的证书

有时候用户想从缓存中删除特定的证书, 为了实现这个目标, 你需要 进入到 auth/ 目录, 然后手动地删除对应的缓存文件. 每一个证书都对应一个单独的文件, 如果查看文件的内容, 你将会看到关键字 和值, 关键字 svn:realmstring 描述了文件与哪一个 服务器关联.

```
$ ls ~/.subversion/auth/svn.simple/
5671adf2865e267db74f09ba6f872c28
3893ed123b39500bca8a0b382839198e
5c3c22968347b390f349ff340196ed39

$ cat ~/.subversion/auth/svn.simple/5671adf2865e267db74f09ba6f872c28

K 8
username
V 3
joe
K 8
password
V 4
blah
K 15
svn:realmstring
V 45
<https://svn.domain.com:443> Joe's repository
END
```

一旦找到了对应的缓存文件, 直接删除即可.

#### 命令行认证

所有的 Subversion 命令都支持选项 --username 和 --password, 选项的作用分别是指定用户名与密码, 这样 Subversion 就不会再提示用户输入这两项信息. 有了这两个选项, 就 可以很方便地在脚本里执行 Subversion 命令, 而不用依赖缓存的认证证书. 除此之外, 如果 Subversion 已经缓存了认证证书, 但你知道这不是你想使 用的那个 (比如多个人使用相同的登录名登录系统, 但每个人所使用的 Subversion 认证证书却不一样), 可以用这两个选项重新指定用户名与密码. 用户可以不指定选项 --password, 只让 Subversion 从 命令行参数中获取用户名, 但它仍然会提示用户输入与用户名对应的密码.

#### 认证小结

关于 Subversion 的认证行为最后再讲一点, 尤其是 --username 和 --password 这两个选项. 很多客户端子 命令都支持这两个选项, 但是要注意使用它们并不会 自动 地把证书发送给服务器, 前面已经说过, 只有当服务器认为需要 证书时, 才会主动向客户端 “索要” 证书, 客户端不能随心所 欲地向服务器 “推送” 证书. 如果在命令行选项上指定了用户 名和 (或) 密码, 只有当服务器需要时, 它们才会被递送给服务器. 使用这 两个选项的最典型情况是用户想要明确地指定用户名, 而不是让 Subversion 自己猜一个 (例如登录操作系统的用户名), 又或者是避免出现交互式的提示 信息 (例如命令是在脚本里执行的).

下面几点介绍了当客户端收到一个认证请求时所做的操作.

* 首先, 客户端检查用户是否在命令行上输入了证书 (选项 --username 和 (或) --password), 如果 是, 客户端将使用它们响应服务器的认证请求.
* 如果命令行参数没有提供证书, 又或者是提供的证书是无效的, 客户 端就在运行时配置的 auth/ 目录查找服务器的 主机名, 端口和认证域, 检查是否有合适的证书缓存. 如果是就使用缓存 的证书响应请求.
* 最后, 如果前面的认证都失败了, 客户端就会提示用户输入用户 名与密码 (除非指定了选项 --non-interactive 或 其他等效的设置).

如果客户端成功地用上面的任意一种方法满足了服务器的认证请求, 它就试图把证书缓存在本地磁盘上 (除非用户禁止了缓存).

## 在没有工作副本的情况下工作

the section called “Subversion 的工作副本” 已经说过, Subversion 的工作 副本是一种暂存区, 暂存用户的私有修改, 当修改完成, 准备共享给其他用户时, 就把修改提交到仓库中. 于是, 用户的大部分时间都是在用客户端与工作副本打 交道, 即使是不处理工作副本的操作 (例如 svn log), 也 经常使用工作副本里的文件或目录作为操作的目标文件.

明确地说, 从工作副本里提交是修改文件的典型方式, 幸运的是这并不是唯一 的选择, 如果修改相对比较简单, 用户甚至可以在不检出工作副本前提提交修改, 本节就是介绍与此有关的内容.

### 远程客户端命令行操作

为了完成一些相对比较小的修改, Subversion 的客户端命令行工具的很 多操作都可以在没有工作副本的前提下, 直接对仓库 URL 发起. 其中的部分 内容在本书的其他地方介绍, 但是为了方便读者, 我们在这里统一进行详细地 介绍.

最明显的远程类提交操作应该是命令 svn import, 我们在 the section called “导入文件和目录” 介绍如何快速地把 一个目录导入到仓库中时, 提到了这个命令.

当目标参数是 URL 时, 命令 svn mkdir 和 svn delete 也可以是远程操作, 这允许用户在没有工作副本的前 提下, 在仓库中添加新的目录或 (递归地) 删除文件. 每次执行这两个命令时, 客户端与服务器的通信过程类似于把工作副本里新增的目录或删除的文件提交 给服务器的过程. 如果认证没有问题, 并且没有发生冲突, 服务器就在一个单独 的版本号里完成添加或删除.

你可以用两个 URL 作为 svn copy 或 svn move 的参数—一个是源, 另一个是目标—直接向 仓库提交文件的复制或移动. 如果是在工作副本里执行, 这两个操作将会是耗时 最长的操作之一, 如果使用仓库的 URL 进行远程操作, 它们就可以在常数时间 内完成. 实际上, 在创建分支时, 人们经常使用 svn copy 远程操作, 这部分内容将在 the section called “创建分支” 介绍.

和普通的 svn commit 一样, 上面介绍的几个远程 操作都接受用户输入一段日志, 描述本次操作做了什么, 输入日志的方式可以 用选项 --file (-F) 或 --message (-m), 如果这两个选项都没有指定, 客户端就会提示用户输入日志消息.

最后, 很多与版本号属性相关的操作都可以直接对仓库发起. 实际上, 这 里谈到的版本号属性比较独特, 因为它们不是存放在工作副本里, 所以它们 必须 在不与工作副本交互的情况下修改. 关于如何管理 Subversion 属性的更多信息, 见 the section called “属性”.

### 使用 svnmucc

客户端命令行工具的远程提交操作的一个缺点是用户每次提交只能执行一 个操作—或者说一种类型的操作. 比如说在一个工作副本内, 为了用一个 全新的目录替换掉旧目录, 先执行 svn delete, 再执行 svn mkdir—是一个很自然的操作. 当用户提交这两 个操作的执行结果时, 仓库将创建一个新的版本号, 该版本号完整地记录了这两 个操作. 但是客户端命令行的远程操作不能在单个版本号中完成这两步操作 —svn delete URL 会创建一个新的版本号并删除目录; svn mkdir URL 会在第二个版本号中完成目录的创建.

幸运的是, Subversion 另外提供了一个工具, 用于把多个远程操作放在一 个提交中完成, 这个工具是 svnmucc—Subversion 多 URL 命令客户端 (Multiple URL Command Client):

```
$ svnmucc --help
Subversion multiple URL command client
usage: svnmucc ACTION...

  Perform one or more Subversion repository URL-based ACTIONs, committing
  the result as a (single) new revision.

Actions:
  cp REV URL1 URL2       : copy URL1@REV to URL2
  mkdir URL              : create new directory URL
  mv URL1 URL2           : move URL1 to URL2
  rm URL                 : delete URL
  put SRC-FILE URL       : add or modify file URL with contents copied from
                           SRC-FILE (use "-" to read from standard input)
  propset NAME VAL URL   : set property NAME on URL to value VAL
  propsetf NAME VAL URL  : set property NAME on URL to value from file VAL
  propdel NAME URL       : delete property NAME from URL
…
```
svnmucc 很多年前就已经包含在 Subversion 的源代 码树中 (那时候称为 mucc), 但是直到 1.8, svnmucc 才享受到完全的支持, 成为 Subversion 客户端命令行工 具套装的正式成员.

svn 可以做到的转换, svnmucc 都可以做到, 但不同的是, svnmucc 的功能并不是把操作 切分成多个子命令. 用户可以在一条命令行上 (或者在一个文件中, 通过选项 --extra-args (-X) 把文件传递给 svnmucc) 输入多个操作及其参数, svnmucc 支持的某些操作模仿了对应的客户端命令行. 读者可能已经注意到 上面输出的操作, 例如 cp, mkdir, mv 和 rm, 和我们在 the section called “远程客户端命令行操作” 提到的操作非常 类似, 但是请记住, 它们之间最关键的区别是用户可以在 svnmucc 的一次调用中, 执行任意多的操作, 所有的这些 操作只会产生一个新的版本号.

如果使用 svnmucc 完成本节开头的远程目录替换操 作, 一个示例是:

```
$ svnmucc rm http://svn.example.com/projects/sandbox \
          mkdir http://svn.example.com/projects/sandbox \
          -m "Replace my old sandbox with a fresh new one."
r22 committed by harry at 2013-01-15T21:45:26.442865Z
$
```

可以看到, svnmucc 在一个版本号中完成了两步操作, 而在没有工作副本的情况下, svn 会产生两个新的版本号.

> 剩下的内容，我觉得没有用，就不复制过来了

# Chapter 4. 分支与合并

分支与合并是版本控制的基础功能, 从概念上解释非常简单, 但是它的复杂性 和各种细微差别值得我们用整整一章进行介绍. 我们将会介绍这些操作背后的基本 思想, 以及 Subversion 在实现上的某些独特之处. 如果读者对 Subversion 的基本 概念 (见 Chapter 1, 基本概念) 还不了解, 在阅读本章之前建议读者先 了解它们.

## 什么是分支

假设你的工作是为公司的某个部门维护文档—比如说一本手册. 一天, 另一个部门也请你替他们维护同一份文档, 但需要根据他们的部门情况, 对手册的 某些部分作一些修改.

对于这种情况你应该怎么处理? 最容易想到的做法是为另一个部门创建一份 文档的副本, 然后单独地对这两份文档进行维护. 每当部门要求对文档进行修改 时, 你就把修改写到相应的文档里.

你应该会经常对两个副本做相同的修改, 比如说你在第一个副本时发现了一 个打字错误, 同样的错误在第二个副本里也应该存在, 毕竟两份文档的大部分内容 都是一样的.

这是分支的基本概念—顾名思义, 它是一条独立存在的开发线, 如果回溯地 足够深, 将会看到它和其他分支共享相同的历史. 一个分支的生命总是开始于复 制操作, 从那儿开始产生自己的历史

![](http://blog.oneforce.cn/images/20180301/ch04dia1.png)

## 使用分支

阅读到这里, 读者应该理解了每一次提交是如何创建一个新的文件系统树 状态 (称为 “版本号”), 如果还不理解, 读者应该回去阅读 the section called “版本号” 的内容.

再次回顾 Chapter 1, 基本概念 的例子: 你和你的同事—Sally —共享一个包含了两个项目的仓库, 这两个项目是 paint 和 calc. 如 Figure 4.2, “仓库的起始布局” 所示, 每一个项目都包含了 子目录 trunk 和 branches. 读 者很快就会明白如此布局的原因.

![](http://blog.oneforce.cn/images/20180301/ch04dia2.png)

假设 Sally 和你都有一份 “calc” 项目的工作副本, 更确切 地说, 你们每个人都有一份 /calc/trunk 的工作副本. 项目的所有材料都放在子目录 trunk 内, 而不是直接放到 /calc 里, 因为开发团队把 /calc/trunk 作为开发 “主线” (main line).

现在团队要求你为软件项目实现一个比较大的特性, 这项工作的时间会比较 长, 而且会影响到项目内的所有文件. 首先想到的第一个问题是你不想干扰 Sally —她目前正在解决软件的几个小问题. Sally 的工作依赖于这样一个事实, 那就是项目的最新版 (存放在 /calc/trunk) 总是可用的. 如果你开始一点一点地提交你的修改, 那肯定会影响到 Sally 的工作, 甚至包括 团队内的其他成员.

一种可能的办法是在你完成全部的修改之前, 不向仓库提交修改, 也不更新 工作副本, 这种情况会持续几周, 但是这会产生很多问题. 首先这不太安全, 如果 你的工作副本或机器遭到破坏, 之前所有的工作都会白费. 第二, 不够灵活, 除非 你手动地把你的修改复制到其他工作副本或机器中, 否则的话你就只能在一个固定 的工作副本上工作, 如果要把半成员品分享给其他人也很麻烦. 一种比较良好的 软件工程做法是允许团队中的其他成员审核你的修改, 如果别人不能看到你在中间 阶段的提交, 你将得不到别人的反馈, 甚至在错误的方向上努力多日, 直到别人 注意到你的工作. 最后, 当你完成所有的修改时, 你可能会发现很难把你的修改 合并到仓库里. Sally (或其他人) 可能在你工作的过程中向仓库提交了很多修改, 几周后, 当你最终执行 svn update 时, 这些修改很难合并 到你的工作副本里.

更好的做法是在仓库中创建一个属于你自己的分支 (或一条开发线), 这样 你就可以保存尚未完成的工作, 也不会干扰到其他人, 还可以与其他人分享你的 工作进度. 下面我们将会介绍具体的步骤.

## 创建分支

创建分支非常简单—就是用命令 svn copy 在 仓库中为项目目录树创建一个副本. 因为项目的源代码放在 /calc/trunk, 所以你要复制的就是这个目录. 那么新副本应该 放在哪里? 分支在仓库里的存放位置由项目自己来决定. 最后, 你的分支需要 一个名字, 用于和其他分支区分开. 分支的名字对 Subversion 而言并不重要 —你可以根据工作的特点为分支取一个你认为最好的名字.

假设团队规定分支存放在目录 branches 内 (这是 最常见的情况), 而 branches 是项目主干的兄弟目录 (在我们这个例子里, 存放分支的目录就是 /calc/branches ). 虽然没什么创意, 但你还是想把新的分支叫做 my-calc-branch, 这就意味着你将会创建一个新目录 /calc/branches/my-calc-branch, 新目录的生命周期 以 /calc/trunk 的副本作为开始.

读者应该已经见过如何在工作副本中, 用命令 svn copy 复制出一个新文件或目录, 除了工作副本, 它还可以完成 远程复制 (remote copy)—复制操作会 立刻提交到仓库中, 产生一个新的版本号, 完全不需要工作副本的参与. 从 命令的形式上看, 只是从一个 URL 中复制出新的一个:

```
$ svn copy ^/calc/trunk ^/calc/branches/my-calc-branch \
           -m "Creating a private branch of /calc/trunk."

Committed revision 341.
$
```

上面的命令立刻在仓库中产生了一次提交, 在版本号 341 创建了一个新 目录, 它是目录 /calc/trunk 的拷贝, 如图 Figure 4.3, “创建了分支后的仓库” 所示. [29] 当然, 使用 svn copy 复制工作副本里的目录来创建分支 也是可以的, 但我们不推荐这种做法, 因为可能会很慢. 在客户端复制目录是 一个线性时间复杂度的操作, 实际上它需要递归地复制目录内的每一个文件和 子目录, 这些文件和子目录都存放在本地磁盘上. 而远程复制是一个时间 复杂度为常量的操作, 大多数用户都是采用这种方式创建分支. 另外, 工作副 本中的目录可能含有混合的版本号, 虽然不会产生有害的影响, 但是在合并时 可能会产生不必要的麻烦. 如果用户选择通过复制工作副本中的目录来创建 分支, 在复制前应该确保被复制的目录不含有本地修改和混合的版本号.

![](http://blog.oneforce.cn/images/20180301/ch04dia3.png)

> 廉价拷贝
> Subversion 的设计非常特殊, 用户复制一个目录时, 不必担心仓库会 增长过大—实际上 Subversion 不会复制任何数据, 作为替代, 它 创建了一个新的目录项, 将其指向一个 已存在 的 目录树. 如果你是一名有经验的 Unix 用户, 马上就能看出来这和硬链接是 同样的概念. 随着文件和目录的修改不断增多, Subversion 会继续尽可能地 利用这种硬链接思想, 只有在必要时 (消除对象的不同版本之间的歧义) 才会 真正地复制数据.
>
> 你会经常听到 Subversion 用户谈论 “廉价拷贝”. 无论 目录有多大, Subversion 都只需要一段极小的, 常量的时间和空间就能完成 复制操作. 实际上, 这个特性也是 Subversion 处理提交操作的基础: 每一 个版本号都是前一个版本号的 “廉价拷贝”, 只有少数几项 被修改了. (关于这部分的更多内容, 请登录到 Subversion 官网, 阅读 Subversion 设计文档中的 “冒泡 (bubble up)” 方法).
>
> 当然, 这些复制和共享数据的内部机制对用户而言都是透明的, 他们只能 看到目录被复制了. 我们的重点是复制在时间和空间上都很廉价, 如果用户是 在仓库内创建分支 (通过执行命令 svn copy URL1 URL2), 操作消耗 的时间是常量的, 而且非常快. 只要用户有需要, 可以随意地创建分支.

## 在分支上工作

创建完分支后, 用户就可以检出它的工作副本, 然后开始工作:

```
$ svn checkout http://svn.example.com/repos/calc/branches/my-calc-branch
A    my-calc-branch/doc
A    my-calc-branch/src
A    my-calc-branch/doc/INSTALL
A    my-calc-branch/src/real.c
A    my-calc-branch/src/main.c
A    my-calc-branch/src/button.c
A    my-calc-branch/src/integer.c
A    my-calc-branch/Makefile
A    my-calc-branch/README
Checked out revision 341.
$
```

和其他工作副本相比, 这个工作副本并没有什么特别的地方, 它只不过是映射 到了仓库的另一个目录. 而 Sally 在更新时将不会看到在这个工作副本里提 交的修改, 因为她的工作副本映射的是 /calc/trunk. (记得看一下本章后面的 the section called “遍历分支”, 它是 创建分支工作副本的另一种办法)

假设分支创建后又过了一周, 期间提交了下面这些修改:

* 在版本号 342 修改了文件 /calc/branches/my-calc-branch/src/button.c
* 在版本号 343 修改了文件 /calc/branches/my-calc-branch/src/integer.c
* Sally 在版本号 344 修改了文件 /calc/trunk/src/integer.c.

现在, 文件 integer.c 产生了两条独立的开发线, 如 Figure 4.4, “一个文件历史的分叉” 所示.

![Figure 4.4. 一个文件历史的分叉](http://blog.oneforce.cn/images/20180301/basic-branch.png)

当用户查看文件 integer.c 副本的修改历史时, 事 情开始变得有趣起来:

```
$ pwd
/home/user/my-calc-branch

$ svn log -v src/integer.c
------------------------------------------------------------------------
r343 | user | 2013-02-15 14:11:09 -0500 (Fri, 15 Feb 2013) | 1 line
Changed paths:
   M /calc/branches/my-calc-branch/src/integer.c

* integer.c:  frozzled the wazjub.
------------------------------------------------------------------------
r341 | user | 2013-02-15 07:41:25 -0500 (Fri, 15 Feb 2013) | 1 line
Changed paths:
   A /calc/branches/my-calc-branch (from /calc/trunk:340)

Creating a private branch of /calc/trunk.
------------------------------------------------------------------------
r154 | sally | 2013-01-30 04:20:03 -0500 (Wed, 30 Jan 2013) | 2 lines
Changed paths:
   M /calc/trunk/src/integer.c

* integer.c:  changed a docstring.
------------------------------------------------------------------------
…
------------------------------------------------------------------------
r113 | sally | 2013-01-26 15:50:21 -0500 (Sat, 26 Jan 2013) | 2 lines
Changed paths:
   M /calc/trunk/src/integer.c

* integer.c: Revise the fooplus API.
------------------------------------------------------------------------
r8 | sally | 2013-01-17 16:55:36 -0500 (Thu, 17 Jan 2013) | 1 line
Changed paths:
   A /calc/trunk/Makefile
   A /calc/trunk/README
   A /calc/trunk/doc/INSTALL
   A /calc/trunk/src/button.c
   A /calc/trunk/src/integer.c
   A /calc/trunk/src/main.c
   A /calc/trunk/src/real.c

Initial trunk code import for calc project.
------------------------------------------------------------------------
```

注意到 Subversion 在追溯分支 my-calc-branch 中的文件 integer.c 的历史时, 即使到达了创建分支 的时间点, 也仍然会继续往下追踪. 在历史中显示的是分支被创建的事件, 这 是因为当 /calc/trunk/ 中所有的文件都被复制时, 自然也就复制了 integer.c. 现在再看一下 Sally 在 她的副本上执行同样的命令会输出什么内容:

```
$ pwd
/home/sally/calc

$ svn log -v src/integer.c
------------------------------------------------------------------------
r344 | sally | 2013-02-15 16:44:44 -0500 (Fri, 15 Feb 2013) | 1 line
Changed paths:
   M /calc/trunk/src/integer.c

Refactor the bazzle functions.
------------------------------------------------------------------------
r154 | sally | 2013-01-30 04:20:03 -0500 (Wed, 30 Jan 2013) | 2 lines
Changed paths:
   M /calc/trunk/src/integer.c

* integer.c:  changed a docstring.
------------------------------------------------------------------------
…
------------------------------------------------------------------------
r113 | sally | 2013-01-26 15:50:21 -0500 (Sat, 26 Jan 2013) | 2 lines
Changed paths:
   M /calc/trunk/src/integer.c

* integer.c: Revise the fooplus API.
------------------------------------------------------------------------
r8 | sally | 2013-01-17 16:55:36 -0500 (Thu, 17 Jan 2013) | 1 line
Changed paths:
   A /calc/trunk/Makefile
   A /calc/trunk/README
   A /calc/trunk/doc/INSTALL
   A /calc/trunk/src/button.c
   A /calc/trunk/src/integer.c
   A /calc/trunk/src/main.c
   A /calc/trunk/src/real.c

Initial trunk code import for calc project.
------------------------------------------------------------------------
```

Sally 看到了她提交的版本号 334, 但没有看到版本号 343. 对 Subversion 而言, 这两个提交影响的是存放在仓库中不同位置上的不同文件, 而 Subversion 的输出 确实 表明了这两个文件共享一段 相同的历史—在创建分支 (版本号 341) 之前, 它们是同一个文件. 也就是因为这个原因, 所以你和 Sally 都能看到版本号 8 到版本号 154 的提交 历史.

### 分支背后的关键概念

在阅读完这一节后, 读者应该牢记以下两点. 第一, 在 Subversion 内部是 没有分支这个概念的—它只知道如何复制. 当用户复制一个目录时, 产生 的新目录被称为 “分支” 完全是用户赋予它的意义, 用户也可以 从其他角度看待它, 但是对于 Subversion 而言, 它只是一个含有额外历史信息 的普通目录.

第二, Subversion 的分支作为 普通的文件系统目录 存在于仓库中, 这和其他版本控制系统不太一样, 其他版本控制系统创建分支的 典型做法是为文件集添加处于额外维度的 “标签”. Subversion 不关心分支目录的存放位置, 但是大多数开发团队都遵循传统做法: 把所有的 分支都放在 branches/ 目录内, 当然, 用户也可以制订 自己的策略.

## 基本合并

现在你和 Sally 并行地在两个分支上进行开发: 你在自己的私有分支上工作, Sally 在项目的主干 (开发主线) 上工作.

如果项目有很多开发人员, 大多数人都会检出主干的工作副本. 如果有人需要 完成一个长期的修改, 而这个修改的中间成果很可能会扰乱主干, 那么比较标准 的做法是为它创建一个私有分支, 把修改都提交到这个分支上, 直到所有的相关 工作都完成为止.

有了分支后, 好消息是你和 Sally 的工作不会互相干扰, 但坏消息是分支 容易偏离主干过远. 记住, “缓慢爬行” 策略的问题是当你完成 分支上的工作时, 把分支上的修改合并到主干上而不产生大量的冲突, 几乎是不 可能的.

因此在工作的过程中, 你和 Sally 会继续分享修改, 哪些修改值得分享完全由你 来决定, Subversion 允许用户有选择地在分支之间 “复制” 修改. 当你在分支上的工作全部完成时, 分支上的整个修改集合就可以被复制到主干上. 用 Subversion 的行话来讲, 把一个分支上的修改复制到其他分支上— 这 种操作称为 合并 (merging), 完成这种操作的命令是 svn merge.

在下面的例子里, 我们假设 Subversion 客户端和服务器端的版本都是 1.8 或之后的版本. 如果客户端或服务器端的版本小于 1.5, 事情就会变得很复杂: 旧版的 Subversion 不会自动跟踪修改, 这就迫使用户必须手工实现类似的效果, 而这种过程相对来说比较痛苦, 具体来说, 用户必须按照合并语法, 详细地指定 被复制的版本号范围 (见本章后面的 the section called “合并语法详解”), 而且还要注 意哪些修改已经合并, 哪些没有. 因此, 我们 强烈 建 议用户不要使用 1.5 版本之前的 Subversion 客户端与服务器端.

### 变更集

在继续之前, 我们需要提醒读者后面的内容会经常讨论到 “修改”. 对版本控制系统有经验的用户经常混用 “修改” (change) 和 “变更集” (changeset) 这两个概念, 但我们必须弄清楚 Subversion 是怎么理解 变更集 ( changeset) 的.

每个人对变更集的理解似乎都有所不同, 至少在变更集对版本控制系统的 意义上, 都有不同的期待. 从我们的角度来说, 变更集只是一个带有独特的名 字的修改集合. 修改可能包括文件的修改, 目录结构的修改, 或元数据的修改. 更一般的说, 变更集只是带有名字的补丁.

在 Subversion 中, 一个全局的版本号 N 确定了仓库中的一棵目录树: 它是仓库在第 N 次提交后的样子. 同时它还确定一个隐式的变更集: 如果用户对目录树 N 和 N-1 进行 比较, 就可以得到与第 N 次提交对应的补丁. 正因为如此, 版本号 N 不仅可以表示一棵 目录树, 还可以表示一个变更集. 如果用户使用了一个问题跟踪系统来管理 问题, 用户就可以使用版本号指代修复问题的特定补丁—例如, “这个问题在 r9238 中解决”, 然后其他人就可以执行 svn log -r 9238 查看修复问题的提交日志, 再用 svn diff -c 9238 查看补丁的具体内容. Subversion 命令 svn merge 也可以使用版本号作为参数 (读者马上就 会看到). 通过指定参数, 用户可以把一个分支上的特定的变更集合并到另一个 分支上: 为 svn merge 添加参数 -c 9238 就可以把变更集 r9238 合并到你的工作副本里.

### 保持分支同步

继续我们的例子, 假设自从你开始在自己的私有分支上工作后, 时间过了一周, 你要添加的新特性还未完成, 但你知道在你工作的同时, 团队里的其他人会 继续向项目的主干 /trunk 提交修改. 最好把主干上 的修改复制到你自己的分支上, 以便确保他们的修改能够与你的分支契合, 这可 以通过 自动同步合并 (automatic sync merge) 完成, 自动同步合并的目的是为了让分支与祖先 分支上的修改保持同步. “自动” 合并的意思是用户只需要提供 合并所需的最小信息 (也就是合并的源以及被合并的工作副本目标), 至少哪些 修改需要合并则交由 Subversion 决定—在自动合并中, 不需要通过 选项 -r 或 -c 向 svn merge 传递变更集.

Subversion 知道分支的历史, 也知道它是在什么时候从主干上分离出来. 为了执行一个同步合并, 首先要确保分支的工作副本是 “干净的” —也就是没有本地修改. 然后只需要执行:

```
$ pwd
/home/user/my-calc-branch

$ svn merge ^/calc/trunk
--- Merging r341 through r351 into '.':
U    doc/INSTALL
U    src/real.c
U    src/button.c
U    Makefile
--- Recording mergeinfo for merge of r341 through r351 into '.':
 U   .
 $
```

命令 svn merge URL 告诉 Subversion 把 URL 上的所有未被合并 的修改都合并到当前工作副本上 (在典型的情况下, 也就是你的工作副本的 根目录). 注意到我们用的是带有脱字符 (^) 的语法 [30], 这样我们 就不用输入完整的主干 URL 地址. 还要注意输出信息中的 “ Recording mergeinfo for merge…”, 这是说合并正在 更新属性 svn:mergeinfo, 我们会在本章后面的 the section called “合并信息和预览” 介绍 svn:mergeinfo.

执行完上面的例子后, 分支的工作副本就包含了本地修改, 而且这些修改 都是创建完分支后, 主干上的修改的副本:
```
$ svn status
M       .
M       Makefile
M       doc/INSTALL
M       src/button.c
M       src/real.c
```

这时候比较明智的操作是使用 svn diff 查看修 改的内容, 并构建测试分支里的代码. 注意当前工作目录 (“ .”) 也被修改了, svn diff 显示它新增了 svn:mergeinfo 属性.

```
$ svn diff --depth empty .
Index: .
===================================================================
--- .   (revision 351)
+++ .   (working copy)

Property changes on: .
___________________________________________________________________
Added: svn:mergeinfo
   Merged /calc/trunk:r341-351
```

这个属性是非常重要的与合并相关的元数据, 用户 不 应该直接修改它的值, 因为后面的 svn merge 会用到该 属性 (关于合并元数据的更多内容, 我们稍后就会进行介绍).

执行完合并后, 可能会有冲突需要处理—就像执行完 svn update 那样—或者可能还需要进行一些小修改, 保证 合并的结果是正确的 (记住, 没有 语法 冲突并不表 示没有 语义 冲突!). 如果合并后产生了很多问题, 用户总是可以用 svn revert . -R 撤消本地的所有 修改, 然后就可以和同事讨论 “怎么回事”. 如果一切都很顺利, 用户就可以把修改提交到仓库里:

```
$ svn commit -m "Sync latest trunk changes to my-calc-branch."
Sending        .
Sending        Makefile
Sending        doc/INSTALL
Sending        src/button.c
Sending        src/real.c
Transmitting file data ....
Committed revision 352.
```

现在, 用户的私有分支就和主干 “同步” 了, 用户也就不用 担心自己的工作和其他人的相差太远.

假设又过去了一周, 你在自己的分支上提交了更多的修改, 而你的同事也 在不断地修改主干. 再一次, 你想把主干上的修改合并到自己的分支上, 于是 执行下面的命令:

```
$ svn merge ^/calc/trunk
svn: E195020: Cannot merge into mixed-revision working copy [352:357]; try up\
dating first
$
```

这种情况可能不在用户的预料之中! 在自己的分支了工作了一周后, 用户 发现工作副本包含了混合的版本号 (见 the section called “版本号混合的工作副本”). 1.7 及之后版本的 svn merge 在默认情况下禁止向含有混合版本号的工作 副本合并, 简单来说, 这是属性 svn:mergeinfo 合并跟踪 方式的限制导致的 (见 the section called “合并信息和预览”), 这些限制意味 着向一个含有混合版本号的工作副本合并将导致无法预料的内容与目录冲突 [31]. 我们不希望产生任何不必要的冲突, 所以先更新工作副 本, 然后再尝试合并.

```
$ svn up
Updating '.':
At revision 361.

$ svn merge ^/calc/trunk
--- Merging r352 through r361 into '.':
U    src/real.c
U    src/main.c
--- Recording mergeinfo for merge of r352 through r361 into '.':
 U   .
```

Subversion 知道主干上的哪些修改已经合并到了分支上, 所以它只会合并 那些未合并过的主干修改. 如果构建和测试都没有问题, 用户就可以用 svn commit 把分支的修改提交到仓库里.

### 子目录合并与子目录合并信息

在本章的大部分例子中, 被合并的目标都是分支 (见 the section called “什么是分支”) 的根目录, 虽然这是最常见的 情况, 但是偶尔也需要直接合并分支的子目录, 这种类型的合并称为 子目录合并 (subtree merge), 它的合并信息也相应地称为 子目录合并信息 (subtree mergeinfo ). 子目录合并和子目录合并信息其实并没有什么特别的地方, 唯一需要注意的一点是: 一个分支上完整的合并记录可能不仅仅记录在分支根 目录的合并信息里, 可能还要查看子目录的合并信息才能得到完整的合并信息. 幸运的是 Subversion 会替用户完成这些操作, 用户几乎不需要直接参与, 用一个简单的例子解释一下:

```
# We need to merge r958 from trunk to branches/proj-X/doc/INSTALL,
# but that revision also affects main.c, which we don't want to merge:
$ svn log --verbose --quiet -r 958 ^/
------------------------------------------------------------------------
r958 | bruce | 2011-10-20 13:28:11 -0400 (Thu, 20 Oct 2011)
Changed paths:
   M /trunk/doc/INSTALL
   M /trunk/src/main.c
------------------------------------------------------------------------

# No problem, we'll do a subtree merge targeting the INSTALL file
# directly, but first take a note of what mergeinfo exists on the
# root of the branch:
$ cd branches/proj-X

$ svn propget svn:mergeinfo --recursive
Properties on '.':
  svn:mergeinfo
    /trunk:651-652

# Now we perform the subtree merge, note that merge source
# and target both point to INSTALL:
$ svn merge ^/trunk/doc/INSTALL doc/INSTALL -c 958
--- Merging r958 into 'doc/INSTALL':
U    doc/INSTALL
--- Recording mergeinfo for merge of r958 into 'doc/INSTALL':
 G   doc/INSTALL

# Once the merge is complete there is now subtree mergeinfo on INSTALL:
$ svn propget svn:mergeinfo --recursive
Properties on '.':
  svn:mergeinfo
    /trunk:651-652
Properties on 'doc/INSTALL':
  svn:mergeinfo
    /trunk/doc/INSTALL:651-652,958

# What if we then decide we do want all of r958? Easy, all we need do is
# repeat the merge of that revision, but this time to the root of the
# branch, Subversion notices the subtree mergeinfo on INSTALL and doesn't
# try to merge any changes to it, only the changes to main.c are merged:
$ svn merge ^/subversion/trunk . -c 958
--- Merging r958 into '.':
U    src/main.c
--- Recording mergeinfo for merge of r958 into '.':
 U   .
--- Eliding mergeinfo from 'doc/INSTALL':
 U   doc/INSTALL
```

你可能会感到奇怪, 为什么上面的例子里我们只合并了 r958, 但 INSTALL 却含有 r651-652 的合并信息, 这是由于合并 信息的继承性, 合并信息的继承性我们会在 合并信息继承 介绍. 另外还要注意 doc/INSTALL 上的子目录合并信息 被移除了, 或者说被 “省略” 了, 这被称为 合并信息 省略 (mergeinfo elision), 当 Subversion 检测到多余的子目录合并信息时, 就会发生这种现象.

### 重新整合分支

如果用户完成了分支上的所有工作, 也就是说新特性已经完成, 你已经准备好 把分支合并到主干上 (这样的话团队中的其他成员就可以分享你的工作成果), 合并 的步骤很简单, 首先把分支与主干同步, 就像之前做过的那样[32]

```
$ svn up # (make sure the working copy is up to date)
Updating '.':
At revision 378.

$ svn merge ^/calc/trunk
--- Merging r362 through r378 into '.':
U    src/main.c
--- Recording mergeinfo for merge of r362 through r378 into '.':
 U   .

$ # build, test, ...

$ svn commit -m "Final merge of trunk changes to my-calc-branch."
Sending        .
Sending        src/main.c
Transmitting file data .
Committed revision 379.
```

现在, 使用 svn merge 把分支上的修改合并到主干 上, 这种类型的合并称为 “自动再整合” (automatic reintegrate) 合并, 在执行合并之前, 用户需要一份 /calc/trunk 的工作 副本, 可以用 svn checkout 或 svn switch (见 the section called “遍历分支”) 获取.


在合并分支前, 主干的工作副本不能含有本地修改, 已切换的路径, 或混合 的版本号 (见 the section called “版本号混合的工作副本”), 这种状 态不仅会带来很多方便, 而且是自动再整合合并所要求的.

一旦准备好了一个整洁的主干工作副本, 用户就可以把分支合并到主干上了:

```
$ pwd
/home/user/calc-trunk

$ svn update
Updating '.':
At revision 379.

$ svn merge ^/calc/branches/my-calc-branch
--- Merging differences between repository URLs into '.':
U    src/real.c
U    src/main.c
U    Makefile
--- Recording mergeinfo for merge between repository URLs into '.':
 U   .

$ # build, test, verify, ...

$ svn commit -m "Merge my-calc-branch back into trunk!"
Sending        .
Sending        Makefile
Sending        src/main.c
Sending        src/real.c
Transmitting file data ...
Committed revision 380.
```

恭喜, 你在分支上提交的修改现在都已经合并到了开发主线. 应该注意的 是和你到目前为止所做的合并操作相比, 自动再整合合并所做的工作不太一样. 之前我们是要求 svn merge 从另一条开发线 (主干) 上 抓取下一个变更集, 然后把变更集复制到另一个条开发线 (你的私有分支) 上. 这种操作非常直接, Subversion 每一次都知道如何从一次停止的地方开始. 在我们前面讲过的例子里, Subversion 第一次是把 /calc/trunk 的 r341-351 合并到 /calc/branches/my-calc-branch, 后来它就继续合并 下一段范围, r351-361, 在最后一次同步, 它又合并了 r361-378.

然而, 在把 /calc/branches/my-calc-branch 合并到 /calc/trunk 时, 其底层的数学行为是非常 不一样的. 特性分支现在已经是同时包含了主干修改和分支私有修改的大杂烩, 所以没办法简单地复制一段连续的版本号范围. 通过使用自动合并, 你是在要求 Subversion 只复制那些分支特有的修改 (具体的实现方式是比较最新版的分支 与主干, 最终得到的差异就是分支所特有的修改).

始终记住自动再整合合并只支持上面描述的使用案例, 由于这个狭隘的 重点, 除了前面提到的要求 (最新的工作副本 [33] , 不含有混合的版本号, 已切换的路径或本地修改) 外, svn merge 的大部分选项都会使它不能正常工作, 如果用户用到了除 --accept, --dry-run, --diff3-cmd, --extensions, --quiet 之外的其他非全局选项, 将会得到一个错误.

既然你的私有分支已经合并到了主干上, 现在就可以把它删除了:

```
$ svn delete ^/calc/branches/my-calc-branch \
             -m "Remove my-calc-branch, reintegrated with trunk in r381."
```

不过, 分支的历史不是很重要吗? 如果有人想查看分支的每一次修改, 审核特性的演变怎么办? 不用担心, 虽然你的分支在 /calc/branches 再也看不到了, 但是它在仓库的历史 里依然存在. 在 /calc/branches 的 URL 上执行 一个简单的 svn log, 就可以看到分支的全部历史. 你的分支甚至可以某一时刻复活, 你期待吗 (见 the section called “恢复已删除的文件”).

分支被合并到主干后, 如果选择不删除分支, 你可能会继续从主干同步 修改, 然后再次重新整合分支 [34]. 如果你这样做了, 那么只有第一次重新整合后的修改 才会被合并到主干上.

### 合并信息和预览

Subversion 跟踪变更集的基本机制—也就是判断哪些修改已经合并到哪些 分支上—是在版本化的属性中记录数据. 更确切地说, 与合并相关的数据 记录在文件和目录的 svn:mergeinfo 属性中. (如果读者 还不了解 Subversion 的属性, 见 the section called “属性”.)

你可以像查看其他属性那样, 查看属性 svn:mergeinfo :

```
$ cd my-calc-branch

$ svn pg svn:mergeinfo -v
Properties on '.':
  svn:mergeinfo
    /calc/trunk:341-378
```

当用户执行 svn merge 时, Subversion 就会自动 更新属性 svn:mergeinfo, 属性的值指出了给定路径上 的哪些修改已经复制到目录上. 在我们之前的例子里, 修改的来源是 /calc/trunk, 被合并的目录是 /calc/branches/my-calc-branch. 旧版的 Subversion 会悄无 声息地维护属性 svn:mergeinfo, 合并后, 用户仍然可 以用命令 svn diff 或 svn status 查看合并产生的修改, 但是当合并操作修改属性 svn:mergeinfo 时不会显示任何提示信息. 而 Subversion 1.7 及以后的版本就 不再这样了, 当合并操作更新属性 svn:mergeinfo 时, Subversion 会给出一些提示信息. 这些提示信息都是以 --- Recording mergeinfo for 开始, 在合并的末尾输出. 不像其他的合并提示信息, 这些信息不是在描述差异被应用到工作副本 (见 the section called “合并语法详解”), 而是在描述 为了跟踪合并而产生的 “家务” 变化.

Subversion 提供了子命令 svn mergeinfo, 用于查看 两个分支间的合并关系, 特别是查看目录吸收了哪些变更集, 或者查看哪些变 更集它是有资格吸收的, 后者提供了一种预览, 预览随后的 svn merge 命令将会复制哪些修改到分支上. 在默认情况下, svn mergeinfo 将会输出两条分支之间的关系的图形化 概览. 回到我们先前的例子, 用命令 svn mergeinfo 分析 /calc/trunk 和 /calc/branches/my-calc-branch 之间的关系:

```
$ cd my-calc-branch

$ svn mergeinfo ^/calc/trunk
    youngest common ancestor
    |         last full merge
    |         |        tip of branch
    |         |        |         repository path

    340                382
    |                  |
  -------| |------------         calc/trunk
     \          /
      \        /
       --| |------------         calc/branches/my-calc-branch
              |        |
              379      382
```

图中显示了 /cal/branches/my-calc-branch 拷贝 自 /calc/trunk@340, 最近的一次自动合并是从分支到 主干的自动再整合合并, 在版本号 380. 注意到图中 没有 显示我们在版本号 352, 362, 372 和 379 执行的自动同步合并, 在每个 方向上只显示了最近的自动合并 [35] 这种默认输出对于获取两个分支之间的合并概览非常有用, 如果想要清楚地看到分支上合并了哪些版本号, 就增加选项 --show-revs=merged:

```
$ svn mergeinfo ^/calc/trunk --show-revs merged
r344
r345
r346
…
r366
r367
r368
```

同样地, 为了查看分支可以从主干上合并哪些修改, 就用选项 --show-revs=eligible:

```
$ svn mergeinfo ^/calc/trunk --show-revs eligible
r380
r381
r382
```

命令 svn mergeinfo 需要一个 “源” URL (修改的来源), 接受一个可选的 “目标” URL (合并修改 的目标). 如果没有指定目标 URL, 命令就把当前工作目录当成目标. 在上面 的例子里, 因为我们要查询的是分支工作副本, 命令假定我们想知道的是主干 URL 上的哪些修改可以合并到 /calc/branches/my-calc-branch .

从 Subversion 1.7 开始, svn mergeinfo 也可以 描述子目录合并信息和不可继承的合并信息. 为了描述子目录合并信息, 要加 上选项 --recursive 或 --depth, 而不可继承的合并信息本来就会被考虑到.

假设有一个分支同时包含了子目录合并信息和不可继承的合并信息:

```
$ svn pg svn:mergeinfo -vR
# Non-inheritable mergeinfo
Properties on '.':
  svn:mergeinfo
    /calc/trunk:354,385-388*
# Subtree mergeinfo
Properties on 'Makefile':
  svn:mergeinfo
    /calc/trunk/Makefile:354,380
```

从合并信息中可以看到 r385-388 只被合并到了分支的根目录上, 但不 包括任何一个子文件. 还可以看到 r380 只被合并到了 Makefile 上. 如果用带上选项 --recursive 的 svn mergeinfo 查看从 /calc/trunk 那里合并了哪些版本号到这个分支上, 我们可以看到其中三个版本号带有星号 标记:

```
$ svn mergeinfo -R --show-revs=merged ^/calc/trunk .
r354
r380*
r385
r386
r387*
r388*
```

星号 * 表示该版本号只是被 部分地 合并到目标上 (对于 --show-revs=eligible, 其星号的意义是 相同的). 对于这个例子而言, 它的意思是说如果我们尝试从 ^/trunk 合并 r380, r387 或 r388, 将会产生更多的修改. 同样地, 因为 r354, r385 和 r386 没有 被星号标记, 所以再次合并这些版本号将不会产生任何修改. [36]

获取合并预览的另一种办法是使用选项 --dry-run:

```
$ svn merge ^/paint/trunk paint-feature-branch --dry-run
--- Merging r290 through r383 into 'paint-feature-branch':
U    paint-feature-branch/src/palettes.c
U    paint-feature-branch/src/brushes.c
U    paint-feature-branch/Makefile

$ svn status
#  nothing printed, working copy is still unchanged.
```
选项 --dry-run 不会真正地去修改工作副本, 它只会 输出一个真正的合并操作 将会 输出的信息. 如果嫌 svn diff 的输出过于详细, 就可以用这个选项获得一个 比较 “高层的” 合并预览.

当然, 预览合并的最佳方法是执行合并. 记住, 执行 svn merge 并不是一个危险的操作 (除非在合并前, 工作副本含有本地修改, 但我们已经强调过不要在这种情况下执行合并). 如果你不喜欢合并的结果, 执行 svn revert . -R 就可以撤消合并产生的修改. 只有在执行了 svn commit 后, 合并的结果才会被提交到 仓库中.

### 撤消修改

人们经常使用 svn merge 撤消已经提交的修改. 假设你正开心地在 /calc/trunk 的工作副本上工作, 突然发现版本号 392 提交的修改是完全错误的, 它就不应该被提交. 此时你可 以用 svn merge 在工作副本中 “撤消” 版本号 392 的修改, 然后把用于撤消 r392 的修改提交到仓库中. 你所要做 的只是指定一个 逆 差异 (对于这个例子而言, 指定 逆差异的命令行参数是 --revision 392:391 或 --change -392).

```
$ svn merge ^/calc/trunk . -c-392
--- Reverse-merging r392 into '.':
U    src/real.c
U    src/main.c
U    src/button.c
U    src/integer.c
--- Recording mergeinfo for reverse merge of r392 into '.':
 U   .

$ svn st
M       src/button.c
M       src/integer.c
M       src/main.c
M       src/real.c

$ svn diff
…
# verify that the change is removed
…

$ svn commit -m "Undoing erroneous change committed in r392."
Sending        src/button.c
Sending        src/integer.c
Sending        src/main.c
Sending        src/real.c
Transmitting file data ....
Committed revision 399.
```

我们以前说过, 可以把版本号当成一个特定的变更集, 通过选项 -r, 可以要求 svn merge 向工作副本应用一 个特定的变更集, 或一段变更集范围. 在上面这个例子里, 我们是要求 svn merge 把变更集 r392 的逆修改应用到工作副本上.

记住, 像这样撤消修改和其他 svn merge 操作一样, 用户应该用 svn status 和 svn diff 确认修改的内容正是心里所期望的那样, 检查没问题后再用 svn commit 提交. 提交后, 在 HEAD 上就再也看 不到 r392 的修改.

读者可能在想: 好吧, 其实并没有真正地撤消提交, 版本号 392 的修改仍然 存在于历史中, 如果有人检出了版本在 r392 到 r398 之间的 calc, 他就会看到错误的修改, 对吧?

说得没错, 当我们谈论 “删除” 一个修改时, 我们实际上说得是 把修改从版本号 HEAD 中删除, 原始的修改仍然存在于仓库中 的历史中. 在大多数时候, 这种做法已经足够好了, 毕竟大多数人只对项目的 HEAD 感兴趣. 然而, 在少数情况下, 用户可能真地需要把 提交从仓库的历史中完全擦除 (可能是不小心提交了一份机密文档). 这做起来并不 容易, 因为 Subversion 的设计目标之一是不能丢失任何一个修改, 版本号是以其他 版本号为基础的不可修改的目录树, 从历史中删除一个版本号将会产生多米诺骨牌 效应, 使后面的版本号产生混乱, 甚至可能会使所有的工作副本失效.[37]


### 恢复已删除的文件

版本控制系统的一大好处是信息永远不会丢失. 即使你删除了一个文件或 目录, 虽然在版本号 HEAD 中已经看不到被删除的文件, 但它们在早先的版本中仍然存在. 新用户经常问的一个问题是 “怎样才 能找回以前的文件或目录?”

第一步是准确地指定你想要恢复的是哪一项条目. 一种比较形象的比喻是 把仓库中的每个对象都想像成一个二维坐标, 第一个坐标是特定的版本号目录 树, 第二个坐标是目录内的路径, 于是文件或目录的每一个版本都可以由一对 坐标唯一地确定.

首先, 用户可能要用 svn log 找到他想恢复的二维 坐标, 比较好的策略是在曾经含有被删除的项目的目录中运行 svn log --verbose, 选项 --verbose (-v) 显示了在每个版本号中, 被修改的所有项目, 你所要做的就是找到那个删除了文件或目录的版本号. 用户 可以依靠自己的肉眼寻找, 也可以借助其他工具 (例如 grep ) 扫描 svn log 的输出. 如果用户已经知道 待恢复的项目是在最近的提交中才被删除, 那还可以用选项 --limit 限制 svn log 的输出.

```
$ cd calc/trunk

$ svn log -v --limit 3
------------------------------------------------------------------------
r401 | sally | 2013-02-19 23:15:44 -0500 (Tue, 19 Feb 2013) | 1 line
Changed paths:
   M /calc/trunk/src/main.c

Follow-up to r400: Fix typos in help text.
------------------------------------------------------------------------
r400 | bill | 2013-02-19 20:55:08 -0500 (Tue, 19 Feb 2013) | 4 lines
Changed paths:
   M /calc/trunk/src/main.c
   D /calc/trunk/src/real.c

* calc/trunk/src/main.c: Update help text.

* calc/trunk/src/real.c: Remove this file, none of the APIs
  implemented here are used anymore.
------------------------------------------------------------------------
r399 | sally | 2013-02-19 20:05:14 -0500 (Tue, 19 Feb 2013) | 1 line
Changed paths:
   M /calc/trunk/src/button.c
   M /calc/trunk/src/integer.c
   M /calc/trunk/src/main.c
   M /calc/trunk/src/real.c

Undoing erroneous change committed in r392.
------------------------------------------------------------------------
```

在上面的例子里, 我们假设要找的文件是 real.c, 通过查看父目录的日志, 可以看到 real.c 是在版本号 400 被删除. 因此, real.c 的最后一个版本就是紧挨着 400 的前一个版本号, 也 就是说你要从版本号 399 中恢复 /calc/trunk/real.c.

这本来是最难的地方—调查. 既然已经知道了要复原的是哪个项目, 接下来你有两个选择.

其中一个选择是使用 svn merge “反向” 应用版本号 400 (我们已经在 the section called “撤消修改” 介绍了如何撤消修改). 命令的效果是把 real.c 重新添加到工作副本里, 提交 后, 文件将重新出现在版本号 HEAD 中.

然而对于我们这个例子而言, 可能并不是最好的办法. 反向应用版本号 400 不仅会添加 real.c, 从版本号 400 的提交日志 可以看到, 反向应用还会撤消 main.c 的某些修改, 这应该不是用户想要的效果. 当然, 你也可以在逆合并完 r400 后, 再手动地 对 main.c 执行 svn revert. 但这种解决办法可扩展性不好, 如果有 90 个文件在 r400 中被修改了, 难道 也要一个个地执行 svn revert 吗?

第二种选择的目的性更强, 不使用 svn merge, 而是 用 svn copy 从仓库中复制特定的版本号与路径 “ 坐标” 到工作副本里:

```
$ svn copy ^/calc/trunk/src/real.c@399 ./real.c
A         real.c

$ svn st
A  +    real.c

# Commit the resurrection.
…
```

状态输出中的加号表示这个项目不仅仅是新增的, 而且还带有历史信息, Subversion 知道它是从哪里复制来的. 以后对 real.c 执行 svn log 将会遍历到 r399 之前的历史, 也就是说 real.c 并不是真正的新文件, 它是已删除的原始文件 的后继, 通常这就是用户想要的效果. 然而, 如果你不想维持文件以前的历史, 还可以下面的方法恢复文件:

```
$ svn cat ^/calc/trunk/src/real.c@399 > ./real.c

$ svn add real.c
A         real.c

# Commit the resurrection.
…
```

虽然我们的例子都是在演示如何恢复被删除的文件, 但同样的技术也可以 用在恢复目录上. 另外, 恢复被删除的文件不仅可以发生在工作副本中, 还可 直接发生在仓库中:

```
$ svn copy ^/calc/trunk/src/real.c@399 ^/calc/trunk/src/real.c \
           -m "Resurrect real.c from revision 399."

Committed revision 402.

$ svn up
Updating '.':
A    real.c
Updated to revision 402.
```

## 高级合并

一旦用户开始频繁地使用分支与合并, 很快就会要求 Subversion 把一个 特定的 的修改从一个地方合并到另一个地方. 为了完成 这项工作, 用户要给 svn merge 传递更多的参数, 下一节 将对命令的语法进行完整地介绍, 同时还将讨论它们的典型应用场景.

### 精选

和术语 “变更集” 一样, 术语 精选 (cherrypicking) 也经常出现在版本控制系统中. 精选指的是这样一种操作: 从分支中挑选 一个 特定的 变更集, 将其复制到其他地方. 精选也可以指这样一种操作: 将一个特定的变更集 集合 (不一定是连续的) 从一个分支复制到另一个分支上. 这和典型的合并 场景相反 (典型的合并场景是自动合并下一段版本号范围).

为什么会有人只想复制单独的一个修改? 这种情况要比你想像的更常发生, 假设你从 /calc/trunk 创建了一个特性分支 /calc/branches/my-calc-feature-branch:

```
$ svn log ^/calc/branches/new-calc-feature-branch -v -r403
------------------------------------------------------------------------
r403 | user | 2013-02-20 03:26:12 -0500 (Wed, 20 Feb 2013) | 1 line
Changed paths:
   A /calc/branches/new-calc-feature-branch (from /calc/trunk:402)

Create a new calc branch for Feature 'X'.
------------------------------------------------------------------------
```

在饮水机接水时, 你听说 Sally 向主干上的 main.c 提交了一个很重要的修改, 通过查看主干的提交历史, 你发现在版本号 413, Sally 修正了一个很严重的错误, 而这个错误也会影响你正在开发的新特性. 你的分支可能还没有准备好合并主干上的所有修改, 但是为了能让工作继续 下去, 你确实需要 r413 的修改.

```
$ svn log ^/calc/trunk -r413 -v
------------------------------------------------------------------------
r413 | sally | 2013-02-21 01:57:51 -0500 (Thu, 21 Feb 2013) | 3 lines
Changed paths:
   M /calc/trunk/src/main.c

Fix issue #22 'Passing a null value in the foo argument
of bar() should be a tolerated, but causes a segfault'.
------------------------------------------------------------------------

$ svn diff ^/calc/trunk -c413
Index: src/main.c
===================================================================
--- src/main.c  (revision 412)
+++ src/main.c  (revision 413)
@@ -34,6 +34,7 @@
…
# Details of the fix
```

就像上面例子中的 svn diff 查看 r413 那样, 你也可以向 svn merge 传递相同的选项:

```
$ cd new-calc-feature-branch

$ svn merge ^/calc/trunk -c413
--- Merging r413 into '.':
U    src/main.c
--- Recording mergeinfo for merge of r413 into '.':
 U   .

$ svn st
 M      .
M       src/main.c
```

如果测试后没什么问题, 就可以把修改提交到仓库中. 提交后, Subversion 更新分支属性 svn:mergeinfo, 以反映 r413 已经合并到 分支中, 这可以避免今后自动同步合并时再去合并 r413 (在同一分支内多次 合并同一修改通常会导致冲突). 还要注意合并信息 /calc/branches/my-calc-branch:341-379, 这条信息 是早先 /calc/trunk 在 r380 再整合合并 /calc/branches/my-calc-branch 时记录的, 当我们 在 r403 创建分支 my-calc-feature-branch 时, 这条合并信息也被一并复制.

```
$ svn pg svn:mergeinfo -v
Properties on '.':
  svn:mergeinfo
    /calc/branches/my-calc-branch:341-379
    /calc/trunk:413
```

从下面 mergeinfo 的输出中可以看到, r413 并没有 被列为可合并的版本号, 这是因为它已经被合并了:

```
$ svn mergeinfo ^/calc/trunk --show-revs eligible
r404
r405
r406
r407
r409
r410
r411
r412
r414
r415
r416
…
r455
r456
r457
```

上面的输出表示当分支要自动同步合并主干时, Subversion 将把合并分成 两步进行, 第一步是合并所有可合并的修改, 直到 r412, 第二步是从 r414 开始 合并所有可合并的修改, 直到 HEAD. 因为我们已经合并了 r413, 所以它会被跳过:

```
$ svn merge ^/calc/trunk
--- Merging r403 through r412 into '.':
U    doc/INSTALL
U    src/main.c
U    src/button.c
U    src/integer.c
U    Makefile
U    README
--- Merging r414 through r458 into '.':
G    doc/INSTALL
G    src/main.c
G    src/integer.c
G    Makefile
--- Recording mergeinfo for merge of r403 through r458 into '.':
 U   .
```

将一个新版本上的修改 回植 ( backporting) 到另一个分支可能是精选修改最常见的需求, 例如, 当开发团队在维护软件的 “发布分支” 时, 就会经常遇到 这种情况 (见 the section called “发布分支”.)

提醒一句: svn diff 和 svn merge 在概念上非常类似, 但在很多情况下它们使用不同的语法, 详情 见 svn Reference—Subversion Command-Line Client. 比如说 svn merge 要求一个工作副本路径作为被合并的操作目标, 如果没有指定, 命令就假设是以 下两种情况之一:

* 被合并的是当前工作目录.
* 用户想把特定文件上的修改合并到当前工作目录的同名文件上.

如果用户在合并目录时没有指定目标路径, svn merge 就认为是第一种情况, 尝试把修改合并到当前工作目录. 如果是合并文件, 并 且这个文件 (或者说名字相同的文件) 在当前工作目录中存在, svn merge 就认为是第二种情况, 尝试把修改合并到具有相同名字的 本地文件上.

### 合并语法详解

读者已经见过了 svn merge 的几个例子, 后面还会 看到几个, 如果你对合并的工作原理感到疑惑, 不用太过自责, 你不是唯一 一个有这种感觉的人. 很多用户 (特别是版本控制的新手) 一开始都会被命令 的语法和适用它们的场景搞蒙. 其实这个命令比你想像中的要简单很多, 有一 个非常简单的办法可以帮助你理解 svn merge 如何工作.

困惑主要来自命令的 名字. 术语 合并 (merge) 在某种程度上表示分支被组合起 来, 或者说有一些神秘的混合数据正在产生. 事实并非如此, 命令更恰当的名 字是 svn diff-and-apply, 因为新名字恰当地描述了 合并过程中所发生的事情: 比较两个仓库目录, 然后把差异应用到工作副本上.

如果你是用 svn merge 在分支之间复制修改, 那么 通常情况下自动合并会工作得很好. 例如下面的命令

```
$ svn merge ^/calc/branches/some-branch
```
尝试把分支 some-branch 上的修改合并到当前 的工作目录上 (假定当前目录是工作副本或工作副本的一部分, 而且和 some-branch 有历史上的联系), 命令只会合并当前 目录还没有的修改. 如果用户在一周后再执行相同的命令, 命令就只会复制在 上一次合并后新出现的修改.

如果用户想通过指定被复制的版本号范围, 最大程度地使用 svn merge, 则命令接受三个参数:

* 一个初始的仓库目录 (通常被叫作比较的 左侧 (left side))
* 一个最终的仓库目录 (通常被叫作比较的 右侧 (right side)
* 接受差异的工作副本 (通常被叫作合并的 目标 (target))

这三个参数一旦指定, Subversion 就比较两个仓库目录, 将比较产生的差异 作为本地修改应用到目标工作副本. 命令执行结束后, 得到的结果和用户手工编 辑文件或执行各种命令 (例如 svn add 和 svn delete) 得到的效果是等价的. 如果合并的结果没什么问题, 用户 就可以把它们提交到仓库中, 如果用户不喜欢合并的结果, 只要用 svn revert 就可以撤消所有的修改.

svn merge 允许用户灵活地指定这三个参数, 下面是 一些例子:

```
$ svn merge http://svn.example.com/repos/branch1@150 \
            http://svn.example.com/repos/branch2@212 \
            my-working-copy

$ svn merge -r 100:200 http://svn.example.com/repos/trunk my-working-copy

$ svn merge -r 100:200 http://svn.example.com/repos/trunk
```

第一种语法显式地指定了三个参数; 如果被比较的是同一 URL 的两个不同 版本号, 可以像第二种语法那样简写, 这种类型的合并称为 “二路 URL ” 合并 (原因显而易见); 第三种语法说明工作副本参数是可选的, 如果省略工作副本参数, 默认是当前工作目录.

虽然第一个例子展示了 svn merge 的 “完整 ” 语法, 但使用时要小心, 它会导致 Subversion 不去更新元数据 svn:mergeinfo, 下一节将对此进行更详细的介绍.

### 没有合并信息的合并

如果可能的话, Subversion 都会去尝试生成合并的元数据, 从而帮助后面 调用的 svn merge 更加智能, 但在某些情况下, svn:mergeinfo 既不会被创建, 也不会被更新, 对这些情况要稍 微注意一点:

* **合并不相关的源** 如果用户要求 Subversion 去比较两个完全不相关的 URL, 那么 Subversion 仍然会生成补丁并应用到工作副本上, 但不会创建或更新 合并元数据. 因为两个源之间没有公共的历史, 而将来的 “智能 ” 合并需要这些公共历史.

* **合并外部仓库** 虽然执行这样一条命令—svn merge -r 100:200 http://svn.foreignproject.com/repos/trunk —是可以的, 但生成的补丁依然缺少 合并元数据. 在撰写本书时, Subversion 还不支持在属性 svn:mergeinfo 内表示多个不同仓库的 URL.

* **使用--ignore-ancestry** 如果向命令 svn merge 传递选项 --ignore-ancestry, 这将导致 svn merge 按照和 svn diff 相同的方式生成 不含有历史的差异, 更多的内容将在 the section called “关注或忽略祖先” 介绍.

* **反向合并目标的修改历史** 在本章的 the section called “撤消修改” 我们 介绍了如何使用 svn merge 应用一个 “逆补丁 ”, 从而回滚已提交的修改. 如果使用这项技术撤消某个对象的已 提交的修改 (例如在主干上提交了 r5, 之后又马上用 svn merge . -c -5 撤消 r5 的修改), 这种类型的合并也不会更新 合并信息.[38]

### 关于合并冲突的更多内容

和 svn update 类似, svn merge 也是向工作副本应用修改, 因此难免会产生冲突. 然而, 与 svn update 相比, 由 svn merge 产生的冲突有 点不同, 本节就是介绍这些不同之处.

在开始前假设用户的工作副本不含有本地修改, 当用户执行 svn update, 把工作副本更新到某个特定的版本号时, 从服务器接收 的修改总能 “干净地” 应用到工作副本上. 服务器生成差异的 方式是比较两棵目录树: 一个是工作副本的虚拟快照, 另一个是用户指定的版本 号所对应的目录树. 因为比较的左侧等价于工作副本, 所以生成的差异总能保证 正确地把工作副本更新到右侧.

但是 svn merge 没有这种保证, 而且冲突可能会更 混乱: 高级用户可以要求服务器比较 任意 两个目录树, 即使目录树和工作副本并不相关! 这就意味着有很大的可能产生人为错误. 用户有时候会比较两个错误的目录树, 导致生成的差异不能被干净地应用到工 作副本上. 命令 svn merge 会尽可能多地把修改应用到 工作副本, 但某些修改可能根本就无法应用成功. 合并错误的常见现象是出现了 意想不到的目标冲突:

```
$ svn merge ^/calc/trunk -r104:115
--- Merging r105 through r115 into '.':
   C doc
   C src/button.c
   C src/integer.c
   C src/real.c
   C src/main.c
--- Recording mergeinfo for merge of r105 through r115 into '.':
 U   .
Summary of conflicts:
  Tree conflicts: 5

$ svn st
 M      .
!     C doc
      >   local dir missing, incoming dir edit upon merge
!     C src/button.c
      >   local file missing, incoming file edit upon merge
!     C src/integer.c
      >   local file missing, incoming file edit upon merge
!     C src/main.c
      >   local file missing, incoming file edit upon merge
!     C src/real.c
      >   local file missing, incoming file edit upon merge
Summary of conflicts:
  Tree conflicts: 5
```

在上面的例子里, 从现象来看, 被比较的目录 doc 和 4 个 \*.c 文件在分支的两个快照中都存在, 生成的 差异想去修改工作副本中对应路径上的文件内容. 但这些路径在工作副本中都 不存在. 无论真实的情况是什么, 产生目录冲突最可能的原因是用户比较了两 个错误的目录树, 或者是差异被应用到了错误的工作副本—这两种都是 用户最常犯的错误. 当错误发生时, 最简单的办法就是递归地撤消由合并产生 的所有本地修改 (svn revert . --recursive), 删除可能残留的未被版本控制的文件和目录, 然后再用正确的参数执行 svn merge.

还要注意, 即使在向不含有本地修改的工作副本合并, 仍有可能产生 内容冲突.

```
$ svn st

$ svn merge ^/paint/trunk -r289:291
--- Merging r290 through r291 into '.':
C    Makefile
--- Recording mergeinfo for merge of r290 through r291 into '.':
 U   .
Summary of conflicts:
  Text conflicts: 1
Conflict discovered in file 'Makefile'.
Select: (p) postpone, (df) diff-full, (e) edit, (m) merge,
        (mc) mine-conflict, (tc) theirs-conflict, (s) show all options: p

$ svn st
 M      .
C       Makefile
?       Makefile.merge-left.r289
?       Makefile.merge-right.r291
?       Makefile.working
Summary of conflicts:
  Text conflicts: 1
```

为什么会发生这种冲突呢? 因为用户可以要求 svn merge 定义并应用任意一个老差异到工作副本中, 而这个差异所包含的 修改可能不能被干净地应用到文件中, 即使这个文件不含有本地修改.

svn update 和 svn merge 的另 一个不同点是当冲突发生时, 新创建的文件的名字. 在 the section called “解决冲突” 我们已经看到更新操作可能会 创建形如 filename.mine, filename.rOLDREV 和 filename.rNEWREV . 的新文件. 当 svn merge 发生冲突时, 它会 创建 3 个形如 filename.working, filename.merge-left.rOLDREV 和 filename.merge-right.rNEWREV 的新文件. 模式中的 “merge-left” 和 “merge-right” 分别指出了文件 来自比较的左侧和右侧, “rOLDREV” 描述了左侧的版本号, 而 “rNEWREV” 描述了右侧的版本号. 无论是 svn update , 还是 svn merge, 这些文件名都可以帮助 用户分辨冲突的来源.

### 拦截修改

有时候, 用户可能不想让某个特定的变更集被自动合并, 比如说你所在的 团队的开发策略是在 /trunk 完成新的开发工作, 但 是, 在向稳定分支回植修改时非常保守, 因为稳定分支是面向发布的分支. 在比较极端的情况下, 你可以手动地从主干精选修改—只精选那些足够 稳定的修改—再合并到分支上. 不过实际做起来可能没这么严格, 大多数时 候你只想让 svn merge 把主干的大多数修改自动合并 到分支上, 这时候就需要一种方法能够屏蔽掉一些特定的变更集, 阻止它们 被自动合并.

为了拦截一个变更集, 必须让 Subversion 认为变更集 已经 被合并了. 为了实现这点, 在执行 svn merge 时添加选项 --record-only, 该选项使得 Subversion 更新 合并信息, 就好像它真得执行了合并, 但实际上文件内容并没有被修改.

```
$ cd my-calc-branch

$ svn merge ^/calc/trunk -r386:388 --record-only
--- Recording mergeinfo for merge of r387 through r388 into '.':
 U   .

# Only the mergeinfo is changed
$ svn st
 M      .

$ svn pg svn:mergeinfo -vR
Properties on '.':
  svn:mergeinfo
    /calc/trunk:341-378,387-388

$ svn commit -m "Block r387-388 from being merged to my-calc-branch."
Sending        .

Committed revision 461.
```

从 Subversion 1.7 开始, 带有选项 --record-only 的合并是传递的, 这就意味着除了在被合并的目标上记录被拦截的合并信息外, 源的 svn:mergeinfo 属性上的任意修改都会被应用到目 标的 svn:mergeinfo 属性上. 举例来说, 我们想要拦截 ^/paint/trunk 上与特性 'paint-python-wrapper' 有关的修改被合并到分支 ^/paint/branches/paint-1.0.x 上. 我们已经知道特性 'paint-python-wrapper' 已经在自己的分支上开发完成, 并且在 r465 合并到了 /paint/trunk 上:

```
$ svn log -v -r465 ^/paint/trunk
------------------------------------------------------------------------
r465 | joe | 2013-02-25 14:05:12 -0500 (Mon, 25 Feb 2013) | 1 line
Changed paths:
   M /paint/trunk
   A /paint/trunk/python (from /paint/branches/paint-python-wrapper/python:464)

Reintegrate Paint Python wrapper.
------------------------------------------------------------------------
```

因为 r465 是一个再整合合并, 所以我们知道描述合并的信息被 记录了下来:

```
$ svn diff ^/paint/trunk --depth empty -c465
Index: .
===================================================================
--- .   (revision 464)
+++ .   (revision 465)

Property changes on: .
___________________________________________________________________
Added: svn:mergeinfo
   Merged /paint/branches/paint-python-wrapper:r463-464
```

如果只是简单地拦截 /paint/trunk 的 r465 并 不能确保万无一失, 因为其他人可能会直接从 /paint/branches/paint-python-wrapper 合并 r462:464, 幸运的是选项 --record-only 的传递性质 可以防止这种情况发生. 选项 --record-only 把 r465 生成的 svn:mergeinfo 差异应用到工作副本上, 从而 拦截住来自 /paint/trunk直接合并和 /paint/branches/paint-python-wrapper 的间接合并.

```
$ cd paint/branches/paint-1.0.x

$ svn merge ^/paint/trunk --record-only -c465
--- Merging r465 into '.':
 U   .
--- Recording mergeinfo for merge of r465 into '.':
 G   .

$ svn diff --depth empty
Index: .
===================================================================
--- .   (revision 462)
+++ .   (working copy)

Property changes on: .
___________________________________________________________________
Added: svn:mergeinfo
   Merged /paint/branches/paint-python-wrapper:r463-464
   Merged /paint/trunk:r465

$ svn ci -m "Block the Python wrappers from the first release of paint."
Sending        .

Committed revision 466.
```

现在, 无论怎么尝试从 /paint/trunk 合并特性都 不会产生任何实际的效果.

```
$ svn merge ^/paint/trunk -c465
--- Recording mergeinfo for merge of r465 into '.':
 U   .

$ svn st # No change!

$ svn merge ^/paint/branches/paint-python-wrapper -r462:464
--- Recording mergeinfo for merge of r463 through r464 into '.':
 U   .

$ svn st  # No change!

$
```
如果以后用户意识到自己实际上 需要 被拦截的 修改, 那么有两种选择. 一种是用户可以撤消 r466, 撤消的方法见 the section called “撤消修改”, 把撤消 r466 的修 改提交后, 用户就可以再次从 /paint/trunk 合并 r465. 另一种是在合并 r465 时带上选项 --ignore-ancestry, 这将导致命令 svn merge 忽略合并信息, 直接应用所 请求的差异, 见 the section called “关注或忽略祖先”.

```
$ svn merge ^/paint/trunk -c465 --ignore-ancestry
--- Merging r465 into '.':
A    python
A    python/paint.py
 G   .
```

使用 --record-only 有一点危险, 因为我们经常无 法分辨什么时候是 “我已经包含了这个修改”, 什么时候是 “我没有这个修改, 但目前还不想要它”. 使用 --record-only 实际上是在向 Subversion 撒谎, 让它以为修改 已经被合并了. 记住修改是否被真正地合并是用户的责任, Subversion 无法 回答 “有哪些修改被拦截了” 这样的问题. 如果用户想跟踪 被拦截的修改 (以后可能会放开对它们的拦截), 就要自己找地方记录, 例如 记在某个文本文件上, 或自定义的属性里.

### 对合并敏感的日志与注释

任意一个版本控制系统都需要支持的一项特性是能够查看是谁, 在什么时 候, 修改了什么地方, Subversion 完成这些功能的命令是 svn log 和 svn blame. 在单独的文件上执行 这两个命令时, 它们不仅会显示影响文件的变更集历史, 还可以精确地指出 每一行是哪个用户在什么时候修改的.

然而, 当修改在分支间复制时, 事情开始变得复杂起来. 比如说用 svn log 查询特性分支的历史, 命令将会显示所有影响 过分支的版本号:

```
$ cd my-calc-branch

$ svn log -q
------------------------------------------------------------------------
r461 | user | 2013-02-25 05:57:48 -0500 (Mon, 25 Feb 2013)
------------------------------------------------------------------------
r379 | user | 2013-02-18 10:56:35 -0500 (Mon, 18 Feb 2013)
------------------------------------------------------------------------
r378 | user | 2013-02-18 09:48:28 -0500 (Mon, 18 Feb 2013)
------------------------------------------------------------------------
…
------------------------------------------------------------------------
r8 | sally | 2013-01-17 16:55:36 -0500 (Thu, 17 Jan 2013)
------------------------------------------------------------------------
r7 | bill | 2013-01-17 16:49:36 -0500 (Thu, 17 Jan 2013)
------------------------------------------------------------------------
r3 | bill | 2013-01-17 09:07:04 -0500 (Thu, 17 Jan 2013)
------------------------------------------------------------------------
```

但是这些日志完整地刻画了分支上的所有修改吗? 输出中没有明确指出的是 r352, r362, r372 和 r379 其实是从主干合并修改的结果. 如果你详细地查看 这几个日志将会发现我们没办法看到构成分支修改的多个主干变更集:

```
$ svn log ^/calc/branches/my-calc-branch -r352 -v
------------------------------------------------------------------------
r352 | user | 2013-02-16 09:35:18 -0500 (Sat, 16 Feb 2013) | 1 line
Changed paths:
   M /calc/branches/my-calc-branch
   M /calc/branches/my-calc-branch/Makefile
   M /calc/branches/my-calc-branch/doc/INSTALL
   M /calc/branches/my-calc-branch/src/button.c
   M /calc/branches/my-calc-branch/src/real.c

Sync latest trunk changes to my-calc-branch.
------------------------------------------------------------------------
```

我们知道被合并的修改来自主干, 那么如何同时查看主干上的这些修改 历史? 答案是使用选项 --use-merge-history (-g ), 展开被合并的 “子” 修改.

```
$ svn log ^/calc/branches/my-calc-branch -r352 -v -g
------------------------------------------------------------------------
r352 | user | 2013-02-16 09:35:18 -0500 (Sat, 16 Feb 2013) | 1 line
Changed paths:
   M /calc/branches/my-calc-branch
   M /calc/branches/my-calc-branch/Makefile
   M /calc/branches/my-calc-branch/doc/INSTALL
   M /calc/branches/my-calc-branch/src/button.c
   M /calc/branches/my-calc-branch/src/real.c

Sync latest trunk changes to my-calc-branch.
------------------------------------------------------------------------
r351 | sally | 2013-02-16 08:04:22 -0500 (Sat, 16 Feb 2013) | 2 lines
Changed paths:
   M /calc/trunk/src/real.c
Merged via: r352

Trunk work on calc project.
------------------------------------------------------------------------
…
------------------------------------------------------------------------
r345 | sally | 2013-02-15 16:51:17 -0500 (Fri, 15 Feb 2013) | 2 lines
Changed paths:
   M /calc/trunk/Makefile
   M /calc/trunk/src/integer.c
Merged via: r352

Trunk work on calc project.
------------------------------------------------------------------------
r344 | sally | 2013-02-15 16:44:44 -0500 (Fri, 15 Feb 2013) | 1 line
Changed paths:
   M /calc/trunk/src/integer.c
Merged via: r352

Refactor the bazzle functions.
------------------------------------------------------------------------
```

为 svn log 增加选项 --use-merge-history (-g), 我们不仅可以看到 r352, 还可以看到通过 r352 从主干合并到分支的提交, 这些提交是 Sally 在主干上的工作. 这才是历 史的更完整的刻画!

命令 svn blame 也支持选项 --use-merge-history (-g), 如果在执行命令时 没有带上该选项, 在查看 src/button.c 每一行的修改注释 时, 用户可能会对修改的负责人产生错误的印象:

```
$ svn blame src/button.c
…
   352    user    retval = inverse_func(button, path);
   352    user    return retval;
   352    user    }
…
```

用户 user 的确在 r352 提交了这 3 行修改, 但其中 2 行实际上来自 Sally 在 r348 的修改, 它们通过同步合并被合并到了分支中:

```
$ svn blame button.c -g
…
G    348    sally   retval = inverse_func(button, path);
G    348    sally   return retval;
     352    user    }
…
```

现在我们知道了是谁应该 真正地 为这 2 行修改 负责!

### 关注或忽略祖先

如果与 Subversion 开发人员交谈, 你可能会经常听到一个术语: 祖先 (ancestry). 这个术语描述了 仓库中两个对象间的一种关系: 如果它们之间是相关的, 那么其中一个对象就 是另一个对象的祖先.

比如说你在 r100 提交了文件 foo.c 的修改, 那么 foo.c@99 就是 foo.c@100 的一个 “祖先”. 另一方面, 如果你在 r101 删除了文件 foo.c, 然后在 r102 又提交了一个具有相同名字的文件, 虽然从名字上看, foo.c@99 和 foo.c@102 是相关的, 但实际上它们是两个完全不相关的对象, 只是碰巧名 字相同罢了, 它们之间不共享历史或 “祖先”.

介绍 “祖先” 是为了说明 svn diff 和 svn merge 之间的一个重要区别. svn diff 会忽略祖先, 而 svn merge 对祖先非常敏感. 举例来说, 如果用户要求 svn diff 去比较 foo.c 在 r99 和 r102 时的版本, 命令将会盲目地比较这两个 版本, 并输出以行为单位的差异. 但是如果用户要求 svn merge 去比较相同的两个对象, 它将会注意到两个对象之间是不相关的, 于是先删除旧文件, 再添加新文件, 从命令的输出信息可以看得很清楚:

```
D    foo.c
A    foo.c
```

大多数合并操作都会涉及比较两个在历史上相关的目录树, 因此 svn merge 就把这种情况当成默认条件. 然而, 在少数情况下用户 可能希望 svn merge 去比较两个不相关的目录树. 比如说 用户导入了两份源代码, 分别表示软件的两个不同的供应商发布版 (见 the section called “供方分支”), 如果用户要求 svn merge 去比较这两个目录树, 将会看到第一个目录树被整 体删除, 然后再整体添加第二个目录树. 对于这种情况, 用户其实是希望 svn merge 只做基于路径的比较, 完全忽略文件和目录 之间的任何关系. 添加选项 --ignore-ancestry 后, svn merge 的行为将变得和 svn diff 一样. (反之, 添加 --notice-ancestry 后, 命令 svn diff 的行为将变得和 svn merge 一样)


### 关注或忽略祖先
如果与 Subversion 开发人员交谈, 你可能会经常听到一个术语: 祖先 (ancestry). 这个术语描述了 仓库中两个对象间的一种关系: 如果它们之间是相关的, 那么其中一个对象就 是另一个对象的祖先.

比如说你在 r100 提交了文件 foo.c 的修改, 那么 foo.c@99 就是 foo.c@100 的一个 “祖先”. 另一方面, 如果你在 r101 删除了文件 foo.c, 然后在 r102 又提交了一个具有相同名字的文件, 虽然从名字上看, foo.c@99 和 foo.c@102 是相关的, 但实际上它们是两个完全不相关的对象, 只是碰巧名 字相同罢了, 它们之间不共享历史或 “祖先”.

介绍 “祖先” 是为了说明 svn diff 和 svn merge 之间的一个重要区别. svn diff 会忽略祖先, 而 svn merge 对祖先非常敏感. 举例来说, 如果用户要求 svn diff 去比较 foo.c 在 r99 和 r102 时的版本, 命令将会盲目地比较这两个 版本, 并输出以行为单位的差异. 但是如果用户要求 svn merge 去比较相同的两个对象, 它将会注意到两个对象之间是不相关的, 于是先删除旧文件, 再添加新文件, 从命令的输出信息可以看得很清楚:

D    foo.c
A    foo.c
大多数合并操作都会涉及比较两个在历史上相关的目录树, 因此 svn merge 就把这种情况当成默认条件. 然而, 在少数情况下用户 可能希望 svn merge 去比较两个不相关的目录树. 比如说 用户导入了两份源代码, 分别表示软件的两个不同的供应商发布版 (见 the section called “供方分支”), 如果用户要求 svn merge 去比较这两个目录树, 将会看到第一个目录树被整 体删除, 然后再整体添加第二个目录树. 对于这种情况, 用户其实是希望 svn merge 只做基于路径的比较, 完全忽略文件和目录 之间的任何关系. 添加选项 --ignore-ancestry 后, svn merge 的行为将变得和 svn diff 一样. (反之, 添加 --notice-ancestry 后, 命令 svn diff 的行为将变得和 svn merge 一样)

### 合并与移动

开发人员的一个常见需求是对代码进行重构, 特别是基于 Java 的软件 项目. 文件和目录被移来移去, 经常会给项目的开发人员造成困扰. 听起来是 不是觉得这种场景很适合使用分支? 创建一个分支, 尽管在分支里随意折腾, 最后再把分支合并到主干上就行了, 对吗?

可惜, 现实情况还没有这么理想, 这是 Subversion 目前还有待完善的地方. 其中的问题是 Subversion 的命令 svn merge 并没有人们 期望中的那样健壮, 尤其是在处理复制和移动操作时.

使用 svn copy 复制一个文件时, 仓库记住了新文件的 来源, 但这项信息并不会传递给正在执行 svn update 或 svn merge 的客户端. 仓库不会告诉客户端 “把 工作副本中已有的这个文件复制到另一个位置”, 相反, 它会向客户端下发 一个全新的 文件. 这可能会导致问题, 尤其是和重命名有关的目录冲突. 重命名不仅涉及到 一个新的副本, 还涉及到删除一个旧路径—一个不为人知的事实是 Subversion 没有 “直正的重命名”—svn move 只不过是 svn copy 和 svn delete 的组合而已.

比如说用户想对自己的私有分支 /calc/branch/my-calc-branch 做一些修改, 首先用户和 /calc/trunk 做了一个自动同步合并, 并在 r470 提交了合并:

```
$ cd calc/trunk

$ svn merge ^/calc/trunk
--- Merging differences between repository URLs into '.':
U    doc/INSTALL
A    FAQ
U    src/main.c
U    src/button.c
U    src/integer.c
U    Makefile
U    README
 U   .
--- Recording mergeinfo for merge between repository URLs into '.':
 U   .

$ svn ci -m "Sync all changes from ^/calc/trunk through r469."
Sending        .
Sending        Makefile
Sending        README
Sending        FAQ
Sending        doc/INSTALL
Sending        src/main.c
Sending        src/button.c
Sending        src/integer.c
Transmitting file data ....
Committed revision 470.
```

然后用户在 r471 把 integer.c 重命名为 whole.c, 又在 r473 修改了 whole.c . 从效果上来看等价于创建了一个新文件 (原文件的副本再加上 一些修改), 再删除原文件. 同时在 /calc/trunk, Sally 在 r472 提交了 integer.c 的修改:

```
$ svn log -v -r472 ^/calc/trunk
------------------------------------------------------------------------
r472 | sally | 2013-02-26 07:05:18 -0500 (Tue, 26 Feb 2013) | 1 line
Changed paths:
   M /calc/trunk/src/integer.c

Trunk work on integer.c.
------------------------------------------------------------------------
```

现在用户打算把自己的分支上的工作合并到主干上, 你觉得 Subversion 会如何组合你和 Sally 的修改?

```
$ svn merge ^/calc/branches/my-calc-branch
--- Merging differences between repository URLs into '.':
   C src/integer.c
 U   src/real.c
A    src/whole.c
--- Recording mergeinfo for merge between repository URLs into '.':
 U   .
Summary of conflicts:
  Tree conflicts: 1

$ svn st
 M      .
      C src/integer.c
      >   local file edit, incoming file delete upon merge
 M      src/real.c
A  +    src/whole.c
Summary of conflicts:
  Tree conflicts: 1
```

实际情况是 Subversion 不会 把这些修改组合起来, 而是产生一个目录冲突[39] 因为 Subversion 需要用户帮它算出你和 Sally 的哪些修改应该留在 whole.c 上, 或者是重命 名操作是否应该保留.

用户解决完目录冲突后才能提交, 这可能需要人工介入, 见 the section called “处理结构性冲突”. 我们举这个例子的目的是提醒 用户, 在 Subversion 改良之前, 要小心对待从一个分支合并复制和重命名操 作到另一个分支, 如果确实这样做了, 要做好解决目录冲突的准备.

### 禁止不支持合并跟踪的客户端

如果用户只是把服务器端升级到 Subversion 1.5 及以后的版本, 那么 1.5 版之前的客户端在 合并跟踪 方面会产生 问题, 这是因为 1.5 版之前的客户端不支持这项特性. 当旧版客户端执行 svn merge 时, 命令不会去更新属性 svn:mergeinfo, 因此, 随后的提交虽然是合并的结果, 但 关于被复制的修改的信息不会告诉给服务器—这些信息就此丢失. 以后, 如果新版客户端执行自动合并, 很可能会因为合并重复的修改而产生大量冲突.

如果你和你的团队非常依赖 Subversion 的合并跟踪特性, 你可能需要对 仓库进行配置, 使得仓库禁止旧客户端提交修改. 最简单的配置方法是在钩子 脚本 start-commit 里检查参数 “capabilities ”, 如果客户端反映它支持 mergeinfo 功能, 钩子脚本就允许客户端提交, 否则的话就禁止该客户端提交修改, Example 4.1, “合并跟踪的看门狗—钩子脚本 start-commit” 给出了 钩子脚本 start-commit 的一个示例:

Example 4.1. 合并跟踪的看门狗—钩子脚本 start-commit

```
#!/usr/bin/env python
import sys

# The start-commit hook is invoked immediately after a Subversion txn is
# created and populated with initial revprops in the process of doing a
# commit. Subversion runs this hook by invoking a program (script,
# executable, binary, etc.) named 'start-commit' (for which this file
# is a template) with the following ordered arguments:
#
#   [1] REPOS-PATH   (the path to this repository)
#   [2] USER         (the authenticated user attempting to commit)
#   [3] CAPABILITIES (a colon-separated list of capabilities reported
#                     by the client; see note below)
#   [4] TXN-NAME     (the name of the commit txn just created)

capabilities = sys.argv[3].split(':')
if "mergeinfo" not in capabilities:
  sys.stderr.write("Commits from merge-tracking-unaware clients are "
                   "not permitted.  Please upgrade to Subversion 1.5 "
                   "or newer.\n")
  sys.exit(1)
sys.exit(0)
```

关于钩子脚本的更多信息, 见 the section called “实现仓库钩子”.

### 关于合并跟踪的最后一点内容

最后要说的是 Subversion 的合并跟踪特性有一个复杂的内部实现, 而 属性 svn:mergeinfo 是用户了解合并跟踪内部机制的 唯一窗口.

记录合并信息的时机和方式有时候会很难理解, 另外, 合并信息元数据的 管理也分成了很多种类型, 例如 “显式” 与 “隐式” 的合并信息, “可实施” 与 “不可实施” 的版本号, “省略” 合并信息的特定机制, 以及从父目录到子目录的 “ 继承”.

我们决定只对这些主题进行简单的介绍, 原因有以下几点. 首先对于一个普 通用户来说, 细节过于复杂; 第二, 普通用户 不需要 完全理解这些概念, 实现上的细节对他们而言是透明的. 如果读者有兴趣, 可以 阅读 CollabNet 的一篇文章: http://www.open.collab.net/community/subversion/articles/merge-info.html.

如果读者只想尽量避开合并跟踪的复杂性, 我们有以下建议:

* 如果是短期的特性分支, 遵循 the section called “基本合并” 描述的步骤.
* 避免子目录合并与子目录合并信息, 只在分支的根目录执行合并, 而不是在分支的子目录或文件上执行合并 (见 the section called “子目录合并与子目录合并信息”).
* 不要直接修改属性 svn:mergeinfo, 而是用 带有选项 --record-only 的命令 svn merge 向属性施加期望的修改, 见 the section called “拦截修改”).
* 被合并的目标应该是一个工作副本, 代表了一个 完整的 目录的根, 这个目录则代表了某一时刻, 仓库的一个单一 位置:
* * 在合并前更新! 不要使用选项 --allow-mixed-revisions 去合并含有混合版本号的工作副本.
* * 不要合并带有 “已切换的” 子目录的目标 (在 the section called “遍历分支” 介绍).
* * 避免合并含有稀疏目录的目标, 类似地, 也不要合并深度不是 --depth=infinity 的目标.
* * 确保你对合并的源具有读权限, 对被合并的目标具有读写权限.

当然, 有时候你并不能完全按照上面所说的要求去做, 此时也不用担心, 只 要你知道这样做的后果就行.

## 遍历分支

命令 svn switch 转换一个已有的工作副本, 使其映射 到另一个不同的分支. 虽然在使用分支时, 该命令并不是必须的, 但它提供了很 方便的快捷键. 在一个我们讲过的例子里, 当用户创建完私有分支后, 检出了该 分支的工作副本. 现在用户多了一种选择, 用命令 svn switch 把 /calc/trunk 的工作副本映射到新创建的分支:

```
$ cd calc
$ svn info | grep URL
URL: http://svn.example.com/repos/calc/trunk
Relative URL: ^/calc/trunk
$ svn switch ^/calc/branches/my-calc-branch
U    integer.c
U    button.c
U    Makefile
Updated to revision 341.
$ svn info | grep URL
URL: http://svn.example.com/repos/calc/branches/my-calc-branch
Relative URL: ^/calc/branches/my-calc-branch
$
```

“切换” 一个不含有本地修改的工作副本到另一个分支, 最终 得到的工作副本就像是从分支上检出的一样. 使用 svn switch 切换分支通常会更有效率, 因为分支之间的差异通常很小, 服务器只需要发送一 小部分数据, 就可以让工作副本映射到一个新的分支.

svn switch 支持选项 --revision (-r), 因此用户还可以把工作副本切换到分支的其他版本, 并 非只能是 HEAD.

当然, 绝大多数项目都要比例子里的 calc 复杂得多, 而且包含非常多的子目录, Subversion 用户在使用分支时经常遵循一些固定的 步骤:

把项目的整个 “主干” 复制到一个新的分支目录.

只把主干工作副本的 “一部分” 进行切换, 以映射到另一 个分支.

换句话说, 如果用户知道分支的工作只需要在某个特定的子目录内完成, 他 就可以用 svn switch, 只把这个子目录切换到分支上 (用户甚至可以只切换一个文件!). 通过这种方式, 用户可以继续接收正常的 “主干” 更新到大部分的工作副本, 但不会更新已切换的部分 (除 非有人向分支提交了修改). 这个特性给 “混合的工作副本” 添加了新的一个维度—工作副本不仅可以包含混合的版本号, 甚至可以包含 混合的仓库位置.

即使工作副本内包含了大量的已切换的子目录, 这些子目录来自仓库中不同 位置, 那么工作副本仍然可以正常工作. 更新工作副本时, 各个子目录也会收到 正确的修改; 提交时, 本地修改仍然作为一个单一的原子修改, 被提交到仓库中.

注意, 虽然 Subversion 允许工作副本映射不同的仓库位置, 但这些位置必须 在 同一个 仓库中. Subversion 还不支持跨仓库的交互, 但以后可能会添加这一特性.[40]

因为 svn switch 本质上是 svn update 的一个变种, 所以它有着和 svn update 相同的行为: 从服务器接收更新时, 工作副本 的本地修改将被保留.

## 标签

另一个常见的版本控制概念是标签. 标签是项目的一个 “快照”, 它在 Subversion 中到处都是, 因为每一个版本号都对应着提交后, 文件系统的 一个快照.

然而, 用户经常想给标签取一个更人性化的名字, 例如 release-1.0 , 而且用户只想对文件系统的某个子目录做快照, 毕竟人们更容易记住 项目的发布版 1.0 是版本号为 4822 的特定子目录.

### 创建简单的标签

创建标签的命令是 svn copy. 如果用户想为 处于 HEAD 的 /calc/trunk 创建一个快照, 就执行:

```
$ svn copy http://svn.example.com/repos/calc/trunk \
           http://svn.example.com/repos/calc/tags/release-1.0 \
           -m "Tagging the 1.0 release of the 'calc' project."

Committed revision 902.
```

这个例子假设目录 /calc/tags 已经存在 (如果不 存在, 就先用 svn mkdir 创建它). 复制完成后, 新目录 release-1.0 就成为了 /calc/trunk 在复制那一刻的永久快照. 当然, 用户也 可以指定被复制的版本号, 避免其他在用户没有觉察的时候, 向仓库提交了新 的修改. 如果说用户已经知道版本号为 901 的 /calc/trunk 正是自己想要的快照, 就给命令 svn copy 添加选项 -r 901.

请等一下, 这和创建分支的步骤不是一样的吗? 事实上的确如此. 对于 Subversion 而言, 标签和分支没有区别, 它们都是通过命令 svn copy 创建的目录. 之所以把复制出的目录叫作 “标签 ” 的唯一原因是 用户 已经决定把该目录看成 标签—只要没有人往标签提交修改, 它就永远保持创建时的样子. 如果用户 在创建标签后, 往标签提交了新的修改, 那它就变成了一个分支.

如果读者是仓库的管理员, 那么你有 2 种标签管理方法. 第 1 种是 “放任不管”: 作为一种项目管理策略, 一开始便规定好标签 的存放位置, 确保所有用户都知道如何对待他们复制的目录 (也就是确保他们不 会向标签提交修改). 第 2 种更具有强制性: 使用和 Subversion 配合的 访问控制脚本, 禁止任何人在标签区提交修改, 除了创建新的标签 (见 Chapter 6, Server Configuration). 第 2 种方法通常是没有必要的, 因 为如果用户不小心向标签提交了修改, 总是可以用之前介绍的方法, 撤消已经 提交的修改.

### 创建复杂的标签

有时候, 用户可能需要更复杂的 “快照”, 它不仅仅是单独 版本号下的单个目录.

举个例子, 假设你的项目比我们的 calc 庞大得 多: 项目内包含了大量的文件与目录. 在工作过程中, 你可能需要创建一个 含有指定特性和问题修正的工作副本, 创建的方式可以是选择性地把文件或 目录退回到指定的版本 (使用带有选项 -r 的 svn update 命令), 把文件和目录切换到特定的分支 (通过命令 svn switch), 甚至是一连串的本地修改. 创建完毕后, 你的工作副本就变成了一个大杂烩, 但是在测试后, 你确定这 正是你想要创建标签的目标.

是时候创建快照了, 但复制 URL 在这里不起作用. 对于这种情况, 用户 想要的是在仓库中, 为当前状态下的工作副本创建一个快照. 幸运的是 svn copy 的 4 种用法中 (见 svn Reference—Subversion Command-Line Client 的 svn copy (cp)), 包含了把工作副本复制到仓库中的能力:

```
$ ls
my-working-copy/

$ svn copy my-working-copy \
           http://svn.example.com/repos/calc/tags/mytag \
           -m "Tag my existing working copy state."

Committed revision 940.
```

现在, 仓库中就出现了一个新目录 /calc/tags/mytag , 它是当前工作副本的快照—混合的版本号, URL, 本地修改 等.

有些用户已经发现了这个特性的其他一些用法. 有时候用户的工作副本 可能包含了一堆本地修改, 他想让其他用户审核一下, 但这次不是用 svn diff 生成并发送补丁 (svn diff 无法体现目录或符号链接的变化), 而是用 svn copy 把 当前状态下的工作副本 “上传” 到仓库中的适当位置, 例如你的 私有目录, 然后其他用户就可以用 svn checkout 逐字 拷贝你的工作副本, 或者用 svn merge 接收你做出的修改.

虽然这是上传工作副本快照的好办法, 但要注意的是这 不是 一个创建分支的好办法, 创建分支应该是它本身的事件, 而这种 方法创建的分支混合了额外的修改, 分支的创建和修改都在一个单独的版本号 里, 这样的话我们以后就难确定哪一个版本号才是分支点.

## 分支维护

读者可能已经注意到 Subversion 非常灵活. 因为 Subversion 实现分支和 标签的底层机制是相同的 (目录复制), 而且分支和标签都是以普通的目录出现 在文件系统中, 很多人觉得自己被 Subversion 吓到了: 这简直就是 过于 灵活了. 本节将介绍一些与管理相关的建议.

### 仓库布局

有一些标准的方式用于组织仓库内容. 大多数用户用目录 trunk 存放开发 “主线”, 用目录 branches 存放分支, 用目录 tags 存放标签. 如果 一个仓库只存放一个项目, 人们通常会创建这些顶层目录:

```
/---
   +/trunk/
   +/branches/
   +/tags/
```

如果在一个仓库中包含了多个项目, 通常根据项目索引它们的布局, 关 于 “项目根目录” 的更多内容, 见 the section called “规划仓库的组织方式”, 下面就是一个典型的, 包含了多个项目的仓库布局:

```
/---
   +/paint/
      +/trunk/
      +/branches/
      +/tags/
   +/calc/
      +/trunk/
      +/branches/
      +/tags/
```

当然, 用户也可以完全忽略这些常见的布局, 按照实际需要定义仓库的 布局. 记住, 无论你怎么选择, 仓库布局并非一成不变, 用户可以在任何时候 重新组织仓库的布局. 因为分支和标签都是普通目录, 所以用户可以随心所欲地 用命令 svn move 移动或重命名它们. 从一种布局切换到 另一种布局只是服务器端的一系列移动而已, 如果你不喜欢当前的仓库布局, 可以任意修改目录结构.

记住, 虽然移动目录很容易操作, 但你仍然需要考虑其他用户. 把目录调 来调去可能会让其他用户感到迷惑, 如果有个用户的工作副本所对应的仓库目录 被其他用户用 svn move 移动其他地方去了, 那么用户下 次执行 svn update 时, 就会被告知工作副本对对应的仓库 目录已经不存在了, 他必须用 svn switch 把工作副本切换 到仓库中的另一个位置.

### 数据的寿命

Subversion 模型具有的另一个优良特性是分支和标签的寿命是有限的, 就像一个普通的被版本控制的条目. 比如说用户最终在自己的分支中完成了工 作, 当分支上所有的修改都被合并到 /calc/trunk 后, 就没必要再在仓库中保留自己的分支了.

```
$ svn delete http://svn.example.com/repos/calc/branches/my-calc-branch \
             -m "Removing obsolete branch of calc project."
Committed revision 474.
```

现在你的分支就消失了, 当然并非永远地消失: 分支只是在 HEAD 上看不到了. 如果用 svn checkout, svn switch 或 svn list 查看较 早的版本号, 仍然可以看到你的旧分支.

如果浏览已删除的目录还不够, 你还可能把它们再恢复回来. 在 Subversion 中恢复数据非常容易, 如果用户想把一个已删除的目录或文件恢复到 HEAD 中, 只需要用 svn copy 把它从旧 版中复制出来即可:

```
$ svn copy ^/calc/branches/my-calc-branch@473 \
           ^/calc/branches/my-calc-branch \
           -m "Restore my-calc-branch."
Committed revision 475.
```
在我们的例子里, 分支的寿命相对较短: 创建分支的目的可能是为了 修正一个问题, 或实现一个新的特性. 当任务完成后, 分支也就走到了生命的 尽头. 在软件开发过程中, 长期同时存在两条 “主要的” 分支并 不少见, 比如说现在要发布 calc 的稳定版本, 而开发 人员知道要花几个月的时间才能把潜在的问题修复殆尽, 也不想向稳定版添加 新特性, 所以你决定创建一个 “稳定” 分支, 表示不想做过多的 修改:

```
$ svn copy ^/calc/trunk ^/calc/branches/stable-1.0 \
           -m "Creating stable branch of calc project."
Committed revision 476.
```

现在开发人员可以自由地向 /calc/trunk 添加最 前沿的 (或实验性的) 新特性, 同时达成一个约定: 只有修复问题的修改才能 提交到 /calc/branches/stable-1.0. 也就是说, 当人 们在主干上工作的同时, 精选修复问题的修改提交到稳定分支上. 即使在稳定 分支发布后, 开发人员很可能也会维护很长一段时间—只要你还在为客户 支持这一发布版. 我们将会在下节介绍更多的相关内容.

## 常见的分支模式

分支和 svn merge 有着非常丰富的用法, 本节介绍 其中最常见的几种.

版本控制最经常用在软件开发领域, 所以本节先介绍 2 种在开发人员中最 常见的分支/合并模式. 如果读者使用 Subversion 不是为了软件开发, 尽管跳过 本节, 如果你是第一次使用版本控制工具的软件开发人员, 请集中注意力, 因为 这些模式经常被经验丰富的程序员看成是最佳的做法. 本节的内容不仅限于 Subversion, 它们同样适用于其他版本控制系统, 使用 Subversion 的术语进行 描述更有助于用户理解.

### 发布分支

大多数软件都有一个典型的生命周期: 编码, 测试, 发布, 如此循环往复. 这个过程有两个问题. 首先开发人员需要不断地往软件添加新特性, 同时质保 团队也会不断地测试稳定版, 开发与测试是同时进行的. 第二, 开发团队通常 需要支持已发布的旧版, 如果在最新版发现了一个问题, 那么旧的发布版很 可能也有同样的问题, 客户更希望直接修复这个问题, 而不是等待新的版本发 布.

版本控制工具可以帮助开发人员解决这些问题, 典型的步骤是:

* 开发人员把所有的新工作都提交到主干上. 把 每天的修改—包含新特性, 问题修复等—都提交到 /trunk.
* 复制主干到 “发布” 分支. 如果团队认为软件已经准备好发布 (例如发布版 1.0), 可能会复制 /trunk 到 /branches/1.0.
* 团队继续并行工作. 一个团队开始对发布分支 进行严格的测试, 其他团队继续在 /trunk 上开发 新的工作 (例如版本 2.0). 如果有问题出现 (无论是在 /trunk, 还是发布分支), 修复问题, 并把修改精选到拥有 相同问题的分支上. 但是这个过程有时候也会停止, 例如为了发布测试而 “冻结” 分支.
* 为分支打标签并发布. 当测试结束, /branches/1.0 被复制到 /tags/1.0.0 , 标签被打包并交付给客户.
* 继续维护分支. 当团队在主干上为版本 2.0 工作时, 修复问题的修改从 /trunk 回植到 /branches/1.0. 如果修改积累得足够多了, 团队 可能决定发布 1.0.1: /branches/1.0 被复制到 /tags/1.0.1, 标签被打包并交付给客户.

整体过程随着软件的成长而不断重复: 当版本 2.0 完成时, 创建了一个新 的 2.0 发布分支, 再对该分支进行测试, 打标签并发布. 几年后, 仓库拥有 了大量的处于 “维护” 状态的发布分支, 以及代表了最终交付 版的标签.

### 特性分支

特性分支 (feature branch) 是分支的一种类型, 它曾是本章的主要例子 (在这个例子中, 你在分支上工作, 而 Sally 在 /trunk 上工作). 这是一个临时分支, 为了完成一 个复杂的修改, 在完成前不能影响 /trunk 的稳定性. 与发布分支不同 (发布分支可能需要永远支持), 特性分支被创建后, 使用一 段时间, 被合并到主干后就会被删除—它们的寿命是很有限的.

在什么样的情况下才需要创建一个特性分支—对于这个问题, 不同的 项目, 其策略也不尽相同. 有些项目甚至根本就不使用特性分支: /trunk 的提交就是一场大混战. 不使用特性分支的好处是操作 简单—开发人员不用了解分支或合并. 缺点是主干上的代码会经常处于不 可用状态. 还有些项目过度使用分支: 没有一个修改是直接提交到主干上的, 即使是非常简单的修改, 也要创建一个短期分支, 认真地审核修改后再合并到 主干, 然后再删除分支. 这样做保证了主干上的代码总是可用的, 但代价就是 极大的过程开销.

大多数项目走的是 “中间路线”. 他们通常会坚持主干上的 代码应该总是可编译的, 而且通过了所有的回归测试. 只有当修改含有大量不 稳定的提交时, 才会创建特性分支. 一条很好的经验法则是: 让一个程序员 单独工作几天, 然后一次性提交所有修改 (于是 /trunk 总是可用的), 如果这个提交所包含的修改过于庞大, 以致于无法审核, 那就 应该在特性分支中完成开发, 然后再合并到主干上. 因为每次提交到分支上的 修改相对较小, 它们可以轻易地被同行审议.

最后, 是如何保持分支与主干 “同步”. 我们之前已经警告 过, 如果连续地在分支上工作几周, 甚至几个月, 同时主干上也有新的提交 出现, 一直到两条开发线之间出现非常大的差异, 此时再把分支合并到主干 上可能会成为一场恶梦.

解决问题最好的办法是定期从主干自动合并到分支, 可以定一个标准, 比如一周合并一次.

当用户终于准备好把 “同步的” 特性分支合并到主干上时, 最后再为特性分支做一次自动同步合并, 合并后分支和主干就是一样的了 (除 了分支特有的修改). 然后再执行自动再整合合并, 把分支合并到主干上.

```
$ cd trunk-working-copy
$ svn update
Updating '.':
At revision 1910.

$ svn merge ^/calc/branches/mybranch
--- Merging differences between repository URLs into '.':
U    real.c
U    integer.c
A    newdirectory
A    newdirectory/newfile
 U   .
…
```
这种分支模式的另一种理解方式是: 每周从主干向分支的同步就像在工作 副本中执行 svn update, 最后从分支到主干的合并就像 在工作副本中执行 svn commit. 毕竟, 工作副本就像是 一个非常浅的私有分支, 一次只能保存一个修改.


## 供方分支

软件开发过程中可能会遇到这样一种情况, 用户所维护的代码依赖其他人的数据, 通常来说, 项目会要求所依赖的数据尽量处于最新状态, 但不能影响稳定性. 只要某个团队所维护的数据会对另一个团队产生直接的影响, 这种场景就会一直 存在.

比如说软件开发人员所开发的应用程序会用到一个第三方函数库, Subversion 和 Apache Portable Runtime (APR) 的关系即是如此, 见 the section called “The Apache Portable Runtime Library”. 为了实现可移植性, Subversion 的源代码依赖于 APR 函数库, 在 Subversion 的早期阶段, 项目 总是紧紧追随 APR 的 API 更新. 现在 Subversion 和 APR 都已经进入成熟期, 所以 Subversion 只使用 APR 经过充分测试的稳定版 API.

如果你的项目依赖其他人的数据, 有若干种方式可以用来同步这些数据. 其中 最麻烦的一种是以口头或书面的方式通知项目的所有成员, 将项目所需的第三方数 据更新到某个特定版本. 如果第三方数据使用 Subversion 进行管理, 就可以利用 Subversion 的外部定义, 快速地将第三方数据更新到特定版本, 并存放在工作 副本中 (见 the section called “外部定义”).

有时候用户可能需要使用自己的版本控制系统去维护第三方代码的定制化 修改. 回到软件开发的例子中, 程序员可以需要修改第三方函数库, 以满足自己 的特殊需求. 这些定制化修改可能包括新功能或问题修正, 直到成为第三方函数 库的官方修改之前, 它们只在内部维护. 或者这些定制化修改永远不会发送给函数 库的官方维护人员, 它们只是为了满足项目的需求而单独存在.

现在你面临一种非常有趣的情况. 你的项目可以使用几种分离的方式存放 第三方数据的定制化修改, 比如说使用补丁文件, 或文件和目录的成熟的替代 版本. 但是维护人员很快就会感到头疼, 因此迫切需要一种机制, 能够方便地把你的定制化修改应用到第三方代码上, 并 且当第三方代码更新时能够迫使开发人员重新生成这些修改.

解决办法是使用 供方分支 (vendor branches). 供方分支是一个存在于你自己的版本控制系统中的 目录, 包含了由第三方提供的数据. 被项目吸收的每一个供方数据版本都称为 一个 供方物资 (vendor drop).

供方分支有两个好处. 首先, 通过在自己的版本控制系统中存放当前支持 的供方物资, 你就可以确认项目成员不必再担心他们是否使用了供方数据的正确 版本, 只需要更新工作副本, 他们就可以得到供方数据的正确版本. 第二, 因为 供方数据使用 Subversion 进行管理, 所以用户可以方便地在仓库中存放自己的 定制化修改, 而无需再使用某种自动的 (或手动的) 方法对定制化修改进行换 入换出.

不幸的是, 在 Subversion 中并不存在一种管理供方分支的最佳方法. 系统 的灵活性提供了多种不同的管理方法, 每一种都有各自的优缺点, 没有一种方法 可以当成 “万能钥匙”. 在下面几节里, 我们将从较高的层面介绍其中几种方法, 所使用的例子也是依赖第三方函数库的 典型示例.

### 通常的供方分支管理过程

维护第三方函数库的定制化修改会牵涉到 3 个数据源: 定制化修改所基于 的第三方函数库的最后一个版本, 项目所使用的定制化版本 (即实际上的供方 分支), 以及第三方函数库的新版本. 于是, 管理供方分支 (供方分支应 存放在用户自己的代码仓库中) 本质上可以归结为 执行合并操作 (指的是一般意义上的合并), 但是其他开发团队可能会对其他 数据源—第三方函数库代码的全新版本—采取不同的策略, 所以说 同样存在几种不同的方法去执行合并操作.

严格来说, 有几种不同的方式用来执行这些合并操作, 为简单起见, 也为了 向读者展示一些具体的东西, 我们假设只有一个供方分支, 每当第三方函数库 发布新版本时, 通过应用当前版本与最新版之间的差异, 将分支更新到新的发 布版本.

下面几节介绍了在几种不同的场景中, 如果创建并管理供方分支. 在下面 的例子里, 我们假设第三方函数库的名字是 libcomplex, 当前供方分支所基于 的版本是 libcomplex 1.0.0, 分支的位置是 ^/vendor/libcomplex-custom. 稍后读者将会看到如何 把供方分支升级到 libcomplex 1.0.1, 同时保留定制化修改.

### 来自外部仓库的供方分支

先来看第一种管理供方分支的方法, 该方法的适用条件是第三方函数库 可以通过 Subversion 进行访问. 为了方便说明, 我们假设函数库 libcomplex 存放在可以公开访问的 Subversion 仓库中, 而且函数库的开发人员也使用了 通常的发布步骤, 即为每一个稳定的发布版创建一个标签.

从 Subversion 1.5 开始, svn merge 支持 外部仓库合并 (foreign repository merges), 也就是合并的源与目标属于不同的仓库. 与旧版相 比, Subversion 1.8 的 svn copy 的行为有所变化: 如果从外部仓库复制目录到工作副本中, 得到的目录将被工作副本收录, 等待 添加到仓库中. 这个特性叫做 外部仓库复制 (foreign repository copy), 我们将用它引导供方 分支.

现在开始创建我们的供方分支. 一开始先在仓库中创建一个存放所有供方 分支的目录, 然后检出该目录的工作副本.

```
$ svn mkdir http://svn.example.com/projects/vendor \
            -m "Create a container for vendor branches."
Committed revision 1160.
$ svn checkout http://svn.example.com/projects/vendor \
               /path/to/vendor
Checked out revision 1160.
$
利用 Subversion 的外部仓库复制特性, 从供方仓库获取 libcomplex 1.0.0 的一份副本—包括文件和目录上所有的 Subversion 属性.

$ cd /path/to/vendor
$
$ svn copy http://svn.othervendor.com/repos/libcomplex/tags/1.0.0 \
           libcomplex-custom
--- Copying from foreign repository URL 'http://svn.othervendor.com/repos/lib\
complex/tags/1.0.0':
A    libcomplex-custom
A    libcomplex-custom/README
A    libcomplex-custom/LICENSE
…
A    libcomplex-custom/src/code.c
A    libcomplex-custom/tests
A    libcomplex-custom/tests/TODO
$ svn commit -m "Initialize libcomplex vendor branch from libcomplex 1.0.0."
Adding         libcomplex-custom
Adding         libcomplex-custom/README
Adding         libcomplex-custom/LICENSE
…
Adding         libcomplex-custom/src
Adding         libcomplex-custom/src/code.h
Adding         libcomplex-custom/src/code.c
Transmitting file data .......................................
Committed revision 1161.
$
```

有了基于 libcomplex 1.0.0 的供方分支后, 我们就可以开始对 libcomplex 进行定制化修改, 然后提交到分支上, 并且可以开始在自己的应用程序中使用 修改后的 libcomplex.

一段时间后, 官方发布了 libcomplex 1.0.1, 查看新版的修改日志后, 我 们决定把自己的供方分支也升级到 1.0.1, 这时候需要用到 Subversion 的 外部仓库合并. 当前的供方分支是原始的 libcomplex 1.0.0 再加上我们的定 制化修改, 现在我们需要把原始的 1.0.0 与 1.0.1 之间的差异应用到供方分 支, 最理想的情况是被应用的差异不会影响到我们的定制化修改. 合并操作需要 使用 二路 URL 形式的 svn merge.

```
$ cd /path/to/vendor
$ svn merge http://svn.othervendor.com/repos/libcomplex/tags/1.0.0 \
            http://svn.othervendor.com/repos/libcomplex/tags/1.0.1 \
            libcomplex-custom
--- Merging differences between foreign repository URLs into '.':
U    libcomplex-custom/src/code.h
C    libcomplex-custom/src/code.c
U    libcomplex-custom/README
Summary of conflicts:
  Text conflicts: 1
Conflict discovered in file 'libcomplex-custom/src/code.c'.
Select: (p) postpone, (df) diff-full, (e) edit, (m) merge,
        (mc) mine-conflict, (tc) theirs-conflict, (s) show all options:
```

可以看到, svn merge 把 libcomplex 1.0.0 升级 到 1.0.1 的修改合并到了我们的工作副本. 在例子中, 有一个文件发生了冲突, 应该是供方修改的区域与我们的定制化修改有所重叠. Subversion 安全地检测 到了冲突, 并询问我们如何解决, 使得定制化修改在 libcomplex 1.0.1 上仍然 有效. (关于冲突解决, 见 the section called “解决冲突”).

冲突一旦解决, 并且测试和审核都没有问题后, 就可以提交到供方分支上.
```
$ svn status libcomplex-custom
M       libcomplex-custom/src/code.h
M       libcomplex-custom/src/code.c
M       libcomplex-custom/README
$ svn commit -m "Upgrade vendor branch to libcomplex 1.0.1." \
             libcomplex-custom
Sending        libcomplex-custom/README
Sending        libcomplex-custom/src/code.h
Sending        libcomplex-custom/src/code.c
Transmitting file data ...
Committed revision 1282.
$
```
这就是当供方源是 Subversion 仓库时, 管理供方分支的方式. 这种方式 有几个值得注意的缺点, 首先, 外部仓库合并不能像同一仓库那样自动跟踪, 这就意味着必须由用户记住供方分支已经做过哪些合并, 以及下次升级时如何 构造合并. 另外—对于其他形式的合并同样适用—源的重命名操作 会造成不小的麻烦, 不幸的是目前并没有有效的办法缓解这个问题.

### 来自镜像源的供方分支

在上一节 (the section called “来自外部仓库的供方分支”) 我们介绍了 当供方物资可通过 Subversion 进行访问时如何实现与维护供方分支. 这是 一种比较理想的情况, 因为 Subversion 非常擅长处理由它进行管理的数据 的合并. 不幸的是, 并不是所有的第三方函数库都可以通过 Subversion 进行 访问. 很多时候, 项目所依赖的函数库是通过非 Subversion 机制交付的, 例如源代码的发布版压缩包. 对于这种情况, 我们强烈建议用户在把非 Subversion 信息导入 Subversion 时, 尽量保持干净. 下面我们将介绍另一 种供方分支管理方法, 其中第三方函数库的发布版将以镜像的方式存放在我 们的仓库中.

首次创建供方分支非常简单, 对于我们的例子而言, 假设 libcomplex 1.0.0 是以代码压缩包的形式发布. 为了创建供方分支, 首先把 libcomplex 1.0.0 的压缩包解压到我们的仓库中, 作为一个只读 (只是一种惯例) 的供方标签.

```
$ tar xvfz libcomplex-1.0.0.tar.gz
libcomplex-1.0.0/
libcomplex-1.0.0/README
libcomplex-1.0.0/LICENSE
…
libcomplex-1.0.0/src/code.c
libcomplex-1.0.0/tests
libcomplex-1.0.0/tests/TODO
$ svn import libcomplex-1.0.0 \
             http://svn.example.com/projects/vendor/libcomplex-1.0.0 \
             --no-ignore --no-auto-props \
             -m "Import libcomplex 1.0.0 sources."
Adding         libcomplex-custom
Adding         libcomplex-custom/README
Adding         libcomplex-custom/LICENSE
…
Adding         libcomplex-custom/src
Adding         libcomplex-custom/src/code.h
Adding         libcomplex-custom/src/code.c
Transmitting file data .......................................
Committed revision 1160.
$
```
注意, 在导入时我们为命令增加了选项 --no-ignore, 这样 Subversion 就不会遗漏任意一个文件或目录, 同时还增加了选项 --no-auto-props, 这样的话, Subversion 客户端就不会生成 供方物资中原本没有的属性信息.[41]

供方发布物资进入我们的仓库后, 接下来就可以用 svn copy 创建供方分支.

```
$ svn copy http://svn.example.com/projects/vendor/libcomplex-1.0.0 \
           http://svn.example.com/projects/vendor/libcomplex-custom \
           -m "Initialize libcomplex vendor branch from libcomplex 1.0.0."
Committed revision 1161.
$
```
现在, 我们拥有了基于 libcomplex 1.0.0 的供方分支, 接下来就可以按照 项目的需要, 对 libcomplex 进行定制化修改—修改完成后直接提交到 刚创建的供方分支里—然后再在自己的项目中使用定制过的 libcomplex.

一段时间后, 发布了 libcomplex 1.0.1. 通过查看修改日志, 我们打算 把供方分支升级到新版. 为了升级供方分支, 我们需要把 1.0.0 和 1.0.1 之间的差异应用到供方分支中, 而且不能影响定制化修改. 完成这项操作最 案例的方式是先把 libcomplex 1.0.1 作为 libcomplex 1.0.0 的增量版本 导入到我们的仓库中, 然后使用 二路 URL 形式的 svn merge, 把差异应用到供方分支中.

事实证明, 有多种方式都可以正确地把 libcomplex 1.0.1 添加到仓库中. [42] 我们在这里介绍的方法相对比较原始, 但作为说明 已经足够了.

记住, 我们希望 libcomplex 1.0.1 在我们这儿的镜像能和 1.0.0 的镜像 共享祖先, 这样的话在把它们之间的差异合并到供方分支时, 能产生最好的效果. 于是, 首先通过复制 “供方标签” libcomplex-1.0.0 创建分支 libcomplex-1.0.1—它最终将变成 libcomplex-1.0.1 的副本.

```
$ svn copy http://svn.example.com/projects/vendor/libcomplex-1.0.0 \
           http://svn.example.com/projects/vendor/libcomplex-1.0.1 \
           -m "Setup a construction zone for libcomplex 1.0.1."
Committed revision 1282.
$
```
现在我们需要检出分支 libcomplex-1.0.1 的工作副本, 然后把工作副本 中的代码升级到 1.0.1. 为了完成这些操作, 我们将利用这样一个事实, 就是 svn checkout 可以覆盖已存在的目录, 并且如果提供了 选项 --force, 那么检出的目录和被覆盖的目标目录之间 的差异将作为本地修改, 留在工作副本中.

```
$ tar xvfz libcomplex-1.0.1.tar.gz
libcomplex-1.0.1/
libcomplex-1.0.1/README
libcomplex-1.0.1/LICENSE
…
libcomplex-1.0.1/src/code.c
libcomplex-1.0.1/tests
libcomplex-1.0.1/tests/TODO
$ svn checkout http://svn.example.com/projects/vendor/libcomplex-1.0.1 \
               libcomplex-1.0.1 \
               --force
E    libcomplex-1.0.1/README
E    libcomplex-1.0.1/LICENSE
E    libcomplex-1.0.1/INSTALL
…
E    libcomplex-1.0.1/src/code.c
E    libcomplex-1.0.1/tests
E    libcomplex-1.0.1/tests/TODO
Checked out revision 1282.
$ svn status libcomplex-1.0.1
M       libcomplex-1.0.1/src/code.h
M       libcomplex-1.0.1/src/code.c
M       libcomplex-1.0.1/README
```
```
可以看到, 在 libcomplex 1.0.1 的目录中检出 libcomplex 1.0.0 的 代码, 将得到一个包含了本地修改的工作副本—正是这些修改, 把 libcomplex 1.0.0 升级到 libcomplex 1.0.1.

的确, 这是一个非常简单的例子, 升级操作只涉及到已有文件的修改. 在实际 工作中, 第三方函数库的新版修改可能还包括添加或删除文件 (目录), 重命名文 件或目录等. 在这种情况下, 把供方标签升级到新版会困难得多, 作为训练, 具体 的升级过程将留给读者完成.[43]

不管怎么, 我们成功地把供方标签的工作副本升级到了 libcomplex 1.0.1, 然后提交修改.
$ svn commit -m "Upgrade vendor branch to libcomplex 1.0.1." \
             libcomplex-1.0.1
Sending        libcomplex-1.0.1/README
Sending        libcomplex-1.0.1/src/code.h
Sending        libcomplex-1.0.1/src/code.c
Transmitting file data ...
Committed revision 1283.
$
```
我们终于准备好了升级供方分支. 记住, 我们的目标是把原始的 1.0.1 和 1.0.0 之间的差异应用到供方分支中. 下面展示了如何使用 二路 URL 形式的 svn merge 去更新供方分支的工作副本.

```
$ svn checkout http://svn.example.com/projects/vendor/libcomplex-custom \
               libcomplex-custom
E    libcomplex-custom/README
E    libcomplex-custom/LICENSE
E    libcomplex-custom/INSTALL
…
E    libcomplex-custom/src/code.c
E    libcomplex-custom/tests
E    libcomplex-custom/tests/TODO
Checked out revision 1283.
$ cd libcomplex-custom
$ svn merge ^/vendor/libcomplex-1.0.0 \
            ^/vendor/libcomplex-1.0.1
--- Merging differences between repository URLs into '.':
U    src/code.h
C    src/code.c
U    README
Summary of conflicts:
  Text conflicts: 1
Conflict discovered in file 'src/code.c'.
Select: (p) postpone, (df) diff-full, (e) edit, (m) merge,
        (mc) mine-conflict, (tc) theirs-conflict, (s) show all options:
```
可以看到, svn merge 将必要的修改合并到工作副本 上, 并将修改区域重叠的文件标记为冲突. Subversion 检测到冲突后, 将允许 用户解决冲突 (使用 the section called “解决冲突” 介绍的方 法), 使得我们的定制化修改在 libcomplex 1.0.1 中仍能正常工作. 冲突一旦 解决, 并且审核与测试后都没出现什么问题, 就可以提交了.

```
$ svn status
M       src/code.h
M       src/code.c
M       README
$ svn commit -m "Upgrade vendor branch to libcomplex 1.0.1."
Sending        README
Sending        src/code.h
Sending        src/code.c
Transmitting file data ...
Committed revision 1284.
$
```
到此为止, 供方分支的升级工作就算完成了. 如果将来还要再次升级, 仍然 可以按照本节介绍的步骤进行操作.

## 分支, 还是不分支?

分支还是不分支—这是一个有趣的问题. 本章非常深入地介绍了与分支 和合并有关的知识, 这两者通常是 Subversion 用户困惑的主要来源. 虽然在分支 的创建和管理中, 需要生搬硬套的内容并不复杂, 但是有些用户经常就是否需要创 建分支而犹豫不决. 读者已经看到, Subversion 可以处理常见的分支管理场景, 所以说决定是否需要为项目创建分支在技术上几乎不会产生什么影响, 它的社会 影响反而占据更大的比重. 下面介绍一些在软件项目中使用分支的好处和代价.

使用分支最明显的好处是隔离性. 提交到分支上的修改不会影其他的开发线, 提交到其他开发线的修改也不会影响分支. 利用这点, 开发人员就能安全地在分支 上开发新特性, 对复杂的问题进行修正, 对代码进行重写等. 无论 Sally 在自己 的分支上怎么折腾, Harry 和团队的其他人都可以不受阻碍地继承他们的工作.

利用分支, 我们可以把相关的修改都组织到一个容易识别的集合中, 比如说修 正某个问题的修改可能由多次提交组成, 这些提交的版本号不是连续的. 用户可能 会用人类容易理解的语言描述它们: "版本号 1534, 1543, 1587 和 1588", 很可 能还要在问题跟踪系统中再手工地生成这些号码. 如果修正问题的修改需要被移植 到其他版本中, 则开发人员还要确保不会遗漏任何一个版本号. 但是, 如果把这些 修改都提交到一个独一无二的分支中, 那么在问题跟踪系统或移植修改时, 只需要 引用分支的名字就能确定是哪些提交.

然而, 使用分支的缺点是它的隔离性 会 与团队的 协作需求相抵触. 取决于同事的工作习惯, 提交到分支上的修改可能不像主线上 的修改那样, 得到非常充分的讨论, 审核与测试. 分支的隔离性会鼓励用户抛弃 版本控制的 “最佳做法”, 导致版本历史难以在事后进行审核. 在长期存在的分支上工作的开发人员有时候需要付出额外的努力, 以确保分支的 演化方向与同事的保持一致. 对于有些分支而言, 这些缺点都不算是问题, 因为 它们只是试探性的分支, 仅仅是在尝试代码库未来的发展方向, 将来不会被整合 到主线上. 但是有一个简单的 事实不容忽视, 那就是代码及其修改如果能得到更多人的审核与理解, 那么对项目 而言通常是有好处的.

并不是说使用分支在技术上一点坏处都没有. 如果读者认真思考, 就会发现 每次检出仓库的工作副本, 从某种意义上来说其实就是在创建分支, 这只是分支 的一种特殊类型, 它只存在于客户端主机, 不在仓库里, 用 svn update 把仓库的修改同步到分支上—非常像特殊情况下的, 简化版的 svn merge;[44] svn commit 等效于重新整合分支. 所以说从 这个角度来看, Subversion 用户其实一直都在和分支与合并打交道. 不用对 更新与合并之间的相似性过于惊讶, Subversion 短处最集中的地方—也就是 对文件和目录重命名的处理, 以及目录冲突的处理—都会给 svn update 和 svn merge 造成麻烦. 不幸的是 svn merge 的麻烦更大, 一个真正的合并操作既不针对特殊 情况, 也不简单. 由于这个原因, 合并操作执行起来比更新更慢, 还要求显式的跟 踪 (通过本章讨论过的属性 svn:mergeinfo) 和历史分析计 算, 而且出错的机会也更多.

分支, 还是不分支? 归根结底还要看开发团队如何把握协作与隔离之间的 平衡.

## 小结

这一章我们讲了很多. 首先介绍了标签和分支的概念, 并说明了 Subversion 如何通过 svn copy 复制目录来实现这两个功能. 然后展示 了如何使用 svn merge 把修改从一个分支复制到另一个分支 上, 或回退错误的修改. 再然后介绍了如何使用 svn switch 创建具有混合位置的工作副本. 最后我们讨论了如何管理分支的组织与生存周期.

记住, Subversion 的分支和标签是很廉价的, 所以当你需要时请尽管使用!

为了方便读者, 下面的表格总结了与分支有关的常见操作及其对应的命令.

Table 4.1. 分支与合并命令

|操作|命令|
|---|---|
|创建一个分支或标签	|svn copy URL1 URL2|
|把工作副本切换到另一个分支或标签	|svn switch URL|
|将分支与主干同步	|svn merge trunkURL; svn commit|
|查看合并历史或可合并的变更集	|svn mergeinfo SOURCE TARGET|
|将分支合并至主干	|svn merge branchURL; svn commit|
|合并一个特定的修改	|svn merge -c REV URL; svn commit|
|合并一段范围的修改	|svn merge -r REV1:REV2 URL; svn commit|
|从自动合并中拦截某个特定的修改	|svn merge -c REV --record-only URL; svn commit|
|合并预览	|svn merge URL --dry-run|
|放弃合并的结果	|svn revert -R .|
|从历史中恢复文件	|svn copy URL@REV localPATH|
|撤消已提交的修改	|svn merge -c -REV URL; svn commit|
|查看对合并敏感的历史	|svn log -g; svn blame -g|
|从工作副本创建一个标签	|svn copy . tagURL|
|重新安排分支或标签的布局	|svn move URL1 URL2|
|删除分支或标签	|svn delete URL|
