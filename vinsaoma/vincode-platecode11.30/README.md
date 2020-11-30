# 插件安装
使用插件时，直接指定插件的路径添加：

ionic cordova plugin add git+ssh://git@git.mancando.cn:2222/cordova-plugin/vincode-platecode.git

删除插件时，需要使用插件ID，如下：
ionic cordova plugin list  列出已经安装插件
cordova plugin remove plugin-id
如：
ionic cordova plugin remove cordova-plugin-yingshi

# 注意

1. 在build.gradle里面添加
allprojects处修改成

  allprojects {
      configurations.all {
          resolutionStrategy.force 'com.android.support:support-v4:24.0.0'
      }
  
      repositories {
          jcenter()
          maven {
              url "https://maven.google.com"
          }
      }
  }


2. 在ios模拟器上运行时出现如下问题
Undefined symbols for architecture x86_64:
  "_OBJC_CLASS_$_SPlate", referenced from:
      objc-class-ref in PlateCameraController.o
  "_OBJC_CLASS_$_VinTyper", referenced from:
      objc-class-ref in VinCameraController.o
只能在真实手机上运行
