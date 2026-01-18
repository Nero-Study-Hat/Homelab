import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  srcDir: "posts",
  
  title: "Homelab Documentation",
  description: "My Homelab documentation.",
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
    ],

    sidebar: [
      {
        text: 'Network',
        items: [
          { text: 'Main', link: '/network/main' },
          { text: 'Traffic Flow', link: '/network/traffic_flow' },
          { text: 'Network Security', link: '/network/network_security' },
          { text: 'Physical Topology', link: '/network/physical_topology' },
        ]
      },
      {
        text: 'Servers',
        items: [
          { text: 'Automation', link: '/servers/automation' },
          { text: 'Monitoring', link: '/servers/monitoring' },
          { text: 'Secret Management', link: '/servers/secret_management' },
        ]
      },
      {
        text: 'Learning',
        items: [
          { text: 'Automation', link: '/servers/automation' },
          { text: 'Monitoring', link: '/servers/monitoring' },
          { text: 'Secret Management', link: '/servers/secret_management' },
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/Nero-Study-Hat/Homelab' }
    ]
  }
})
