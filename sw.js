const CACHE_NAME = 'cex-exchange-v1.0.1';
const urlsToCache = [
  '/',
  '/index.html',
  '/manifest.json',
  '/crypto-exchange-complete.html'
];

// 安装事件
self.addEventListener('install', (event) => {
  console.log('Service Worker: 安装中...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('Service Worker: 缓存已打开');
        return cache.addAll(urlsToCache);
      })
      .then(() => {
        console.log('Service Worker: 安装完成');
        // 强制激活新的Service Worker
        return self.skipWaiting();
      })
  );
});

// 获取事件 - 改进的缓存策略
self.addEventListener('fetch', (event) => {
  // 只缓存同源请求
  if (!event.request.url.startsWith(self.location.origin)) {
    return;
  }
  
  // 对于API请求，优先使用网络
  if (event.request.url.includes('/api/') || 
      event.request.url.includes('binance.com') ||
      event.request.url.includes('coingecko.com')) {
    event.respondWith(
      fetch(event.request)
        .catch(() => {
          // 网络失败时返回错误响应
          return new Response(
            JSON.stringify({ error: '网络不可用，请稍后重试' }),
            { 
              status: 503,
              statusText: 'Service Unavailable',
              headers: { 'Content-Type': 'application/json' }
            }
          );
        })
    );
    return;
  }
  
  // 对于静态资源，使用缓存优先策略
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        // 如果缓存中有响应，则返回缓存的版本
        if (response) {
          return response;
        }
        
        // 否则从网络获取
        return fetch(event.request).then((response) => {
          // 检查是否收到有效响应
          if (!response || response.status !== 200 || response.type !== 'basic') {
            return response;
          }
          
          // 克隆响应
          const responseToCache = response.clone();
          
          caches.open(CACHE_NAME)
            .then((cache) => {
              cache.put(event.request, responseToCache);
            });
          
          return response;
        }).catch(() => {
          // 网络失败时，如果是页面请求，返回离线页面
          if (event.request.mode === 'navigate') {
            return caches.match('/index.html');
          }
          throw error;
        });
      })
  );
});

// 激活事件 - 清理旧缓存
self.addEventListener('activate', (event) => {
  console.log('Service Worker: 激活中...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            console.log('Service Worker: 删除旧缓存:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      console.log('Service Worker: 激活完成');
      // 立即控制所有客户端
      return self.clients.claim();
    })
  );
});

// 新增: 后台同步事件
self.addEventListener('sync', (event) => {
  if (event.tag === 'background-sync') {
    console.log('Service Worker: 执行后台同步');
    // 这里可以添加离线数据同步逻辑
  }
});

// 新增: 推送通知事件
self.addEventListener('push', (event) => {
  if (event.data) {
    const data = event.data.json();
    const options = {
      body: data.body,
      icon: '/icon-192.png',
      badge: '/icon-72.png',
      vibrate: [100, 50, 100],
      data: {
        dateOfArrival: Date.now(),
        primaryKey: data.primaryKey
      },
      actions: [
        {
          action: 'explore',
          title: '查看详情',
          icon: '/icon-192.png'
        },
        {
          action: 'close',
          title: '关闭',
          icon: '/icon-192.png'
        }
      ]
    };
    
    event.waitUntil(
      self.registration.showNotification(data.title, options)
    );
  }
});
