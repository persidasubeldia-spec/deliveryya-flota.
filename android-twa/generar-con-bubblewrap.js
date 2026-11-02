const {TwaManifest,TwaGenerator,ConsoleLog}=require('@bubblewrap/core');
(async()=>{
const m=new TwaManifest({
 packageId:'py.deliveryya.flota',host:'deliveryya-flota.pages.dev',name:'DeliveryYa Flota',launcherName:'DeliveryYa Flota',
 display:'standalone',orientation:'portrait',themeColor:'#0B2A5E',themeColorDark:'#0B2A5E',navigationColor:'#0B2A5E',navigationColorDark:'#0B2A5E',
 navigationDividerColor:'#0B2A5E',navigationDividerColorDark:'#0B2A5E',backgroundColor:'#0B2A5E',enableNotifications:false,
 startUrl:'/app.html',iconUrl:'http://localhost:8791/icon.png',maskableIconUrl:'http://localhost:8791/maskable.png',
 splashScreenFadeOutDuration:300,signingKey:{path:'RUTA/upload.jks',alias:'upload'},
 appVersionCode:2,appVersionName:'1.0.1',shortcuts:[],generatorApp:'bubblewrap-cli',fallbackType:'customtabs',
 enableSiteSettingsShortcut:true,isChromeOSOnly:false,isMetaQuest:false,minSdkVersion:24,features:{},alphaDependencies:{enabled:false},
 webManifestUrl:'https://deliveryya-flota.pages.dev/manifest.webmanifest',fullScopeUrl:'https://deliveryya-flota.pages.dev/'});
const errs=m.validate?m.validate():null;if(errs)console.log('validate:',errs);
await new TwaGenerator().createTwaProject('./salida',m,new ConsoleLog('gen'));console.log('OK');})().catch(e=>{console.error('ERR',e);process.exit(1)});
