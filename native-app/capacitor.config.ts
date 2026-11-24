import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'app.tirada.anon',
  appName: 'TiradA anon',
  webDir: 'www',
  backgroundColor: '#050505',
  android: {
    backgroundColor: '#050505'
  },
  plugins: {
    SplashScreen: {
      // No splash show at all: the app opens straight into the map.
      // (Yasha, 2026-11-24: kill the millisecond of icon/avatar at launch.)
      launchShowDuration: 0,
      launchAutoHide: true,
      backgroundColor: '#050505',
      showSpinner: false
    }
  }
};

export default config;
