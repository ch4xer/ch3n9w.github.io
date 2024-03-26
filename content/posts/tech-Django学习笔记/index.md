---
title: Django学习笔记
author: ch3n9w
typora-root-url: ../
date: 2020-01-28 18:48:34
categories: 技术
---

> Django学习的个人笔记

<!--more-->

学习 https://www.zmrenwu.com/courses/hellodjango-blog-tutorial

新建应用, app和project的关系就像是插件一样, 每个app插入project中使用.

```
pipenv run python manage.py startapp blog
```

新建完应用之后必须要在django的配置文件``setting.py``中注册这个应用, 否则就只是一个文件夹而已



django提供了 ORM（Object Relational Mapping）系统, 可以将python代码翻译到对应的数据库操作语言, 这些要写在``models.py``里面, 里面的每一个类都是一个数据表, 类的属性对应着一列



写完后回到``manager.py``同级目录下执行

```
pipenv run python manage.py makemigrations --> 在应用目录下的migrations目录中生成一个py文件来记录对模型的修改
pipenv run python manage.py migrate -->对数据库进行真正的操作
```

对数据库进行交互式操作

```
pipenv run python manage.py shell
```

存取

```
>>> from blog.models import Category, Tag, Post
>>> from django.utils import timezone
>>> from django.contrib.auth.models import User
>>> user = User.objects.get(username='myuser')
>>> c = Category.objects.get(name='categories test')
>>> p = Post(title='title test', body='body test', created_time=timezone.now(), modified_time=timezone.now(), categories=c, author=user)
>>> p.save()
```

查看

```
>>> from blog.models import Category, Tag, Post
>>> Category.objects.all()
<QuerySet [<Category: categories test>]>
>>> Tag.objects.all()
<QuerySet [<Tag: tag test>]>
>>> Post.objects.all()
<QuerySet [<Post: title test>]>
>>> Post.objects.get(title='title test')
<Post: title test>
```

修改

```
>>> c = Category.objects.get(name='categories test')
>>> c.name = 'categories test new'
>>> c.save()
>>> Category.objects.all()
<QuerySet [<Category: test categories new>]>
```

删除

```
>>> p = Post.objects.get(title='title test')
>>> p
<Post: title test>
>>> p.delete()
(1, {'blog.Post_tags': 0, 'blog.Post': 1})
>>> Post.objects.all()
<QuerySet []>
```



路由规则:

- 找到urls.py , 每一个url都会有和它绑定在一起的函数, 这个函数来处理请求
- 这些函数都写在views.py中
- 一个app中的urls.py需要在主目录中的urls.py中注册



模板(templates)集中放置在项目根目录下面, 然后templates下的模板根据不同的app放置在不同的目录中去

使用模板``index.html``

```python
blog/views.py

from django.shortcuts import render
from .models import Post

def index(request):
    post_list = Post.objects.all().order_by('-created_time')
    return render(request, 'blog/index.html', context={'post_list': post_list})
```



创建超级用户来进行后台管理

```
pipenv run python manage.py createsuperuser
```

然后要在``admin.py``中将各个模型注册进去

