// Minimal in-process OFX host for controller/lifecycle contract tests.
// This is not a substitute for acceptance testing in DaVinci Resolve.
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <ofxImageEffect.h>
#include <ofxParam.h>
#include <ofxMessage.h>
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdarg>
#include <cstdint>
#include <filesystem>
#include <iostream>
#include <map>
#include <memory>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>
#pragma comment(lib, "ws2_32.lib")

struct Props {
  std::map<std::string,std::vector<int>> ints;
  std::map<std::string,std::vector<double>> doubles;
  std::map<std::string,std::vector<std::string>> strings;
  std::map<std::string,std::vector<void*>> pointers;
};
template<class T> OfxStatus put(std::map<std::string,std::vector<T>>& m,const char* k,int i,T v) {
  if(!k||i<0) return kOfxStatErrBadIndex;
  auto& a=m[k]; if(a.size()<=size_t(i))a.resize(i+1); a[i]=v; return kOfxStatOK;
}
template<class T> OfxStatus get(std::map<std::string,std::vector<T>>& m,const char* k,int i,T* v) {
  if(!v)return kOfxStatErrBadHandle; *v=T{}; auto it=m.find(k?k:"");
  if(it==m.end()||i<0||size_t(i)>=it->second.size())return kOfxStatErrUnknown;
  *v=it->second[i];return kOfxStatOK;
}
Props& p(OfxPropertySetHandle h){return *reinterpret_cast<Props*>(h);}
OfxPropertySetHandle ph(Props& a){return reinterpret_cast<OfxPropertySetHandle>(&a);}
OfxStatus sp(OfxPropertySetHandle h,const char*k,int i,void*v){return put(p(h).pointers,k,i,v);}
OfxStatus ss(OfxPropertySetHandle h,const char*k,int i,const char*v){return put(p(h).strings,k,i,std::string(v?v:""));}
OfxStatus sd(OfxPropertySetHandle h,const char*k,int i,double v){return put(p(h).doubles,k,i,v);}
OfxStatus si(OfxPropertySetHandle h,const char*k,int i,int v){return put(p(h).ints,k,i,v);}
OfxStatus gp(OfxPropertySetHandle h,const char*k,int i,void**v){return get(p(h).pointers,k,i,v);}
OfxStatus gd(OfxPropertySetHandle h,const char*k,int i,double*v){return get(p(h).doubles,k,i,v);}
OfxStatus gi(OfxPropertySetHandle h,const char*k,int i,int*v){return get(p(h).ints,k,i,v);}
OfxStatus gs(OfxPropertySetHandle h,const char*k,int i,char**v){
  *v=nullptr;auto it=p(h).strings.find(k);if(it==p(h).strings.end()||i<0||size_t(i)>=it->second.size())return kOfxStatErrUnknown;
  *v=const_cast<char*>(it->second[i].c_str());return kOfxStatOK;
}
#define MULTISET(name,one,T) OfxStatus name(OfxPropertySetHandle h,const char*k,int n,T v){for(int i=0;i<n;i++){auto s=one(h,k,i,v[i]);if(s!=kOfxStatOK)return s;}return kOfxStatOK;}
MULTISET(spn,sp,void*const*) MULTISET(ssn,ss,const char*const*) MULTISET(sdn,sd,const double*) MULTISET(sin,si,const int*)
#define MULTIGET(name,one,T) OfxStatus name(OfxPropertySetHandle h,const char*k,int n,T v){for(int i=0;i<n;i++){auto s=one(h,k,i,&v[i]);if(s!=kOfxStatOK)return s;}return kOfxStatOK;}
MULTIGET(gpn,gp,void**) MULTIGET(gsn,gs,char**) MULTIGET(gdn,gd,double*) MULTIGET(gin,gi,int*)
OfxStatus resetProp(OfxPropertySetHandle h,const char*k){p(h).ints.erase(k);p(h).doubles.erase(k);p(h).strings.erase(k);p(h).pointers.erase(k);return kOfxStatOK;}
OfxStatus dimension(OfxPropertySetHandle h,const char*k,int*n){auto&a=p(h);*n=0;if(a.ints.count(k))*n=int(a.ints[k].size());if(a.doubles.count(k))*n=int(a.doubles[k].size());if(a.strings.count(k))*n=int(a.strings[k].size());if(a.pointers.count(k))*n=int(a.pointers[k].size());return *n?kOfxStatOK:kOfxStatErrUnknown;}

struct Param{Props props;std::string type,name,text;std::vector<double> values;unsigned keys=0;};
struct ParamSet{Props props;std::map<std::string,std::unique_ptr<Param>> params;};
struct Effect{Props props;ParamSet params;Props source,output;};
Param& param(OfxParamHandle h){return *reinterpret_cast<Param*>(h);}
ParamSet& set(OfxParamSetHandle h){return *reinterpret_cast<ParamSet*>(h);}
std::thread::id hostThread=std::this_thread::get_id();
std::string hostAction;
int illegalWrites=0,illegalKeyReads=0,editDepth=0,editBegins=0,editEnds=0;
bool canWrite(){return std::this_thread::get_id()==hostThread&&(hostAction==kOfxActionInstanceChanged||hostAction==kOfxActionCreateInstance);}
void checkWrite(){if(!canWrite())++illegalWrites;}
int components(const Param&a){if(a.type==kOfxParamTypeDouble3D||a.type==kOfxParamTypeRGB)return 3;if(a.type==kOfxParamTypeDouble2D)return 2;return 1;}
bool floating(const Param&a){return a.type==kOfxParamTypeDouble||a.type==kOfxParamTypeDouble2D||a.type==kOfxParamTypeDouble3D||a.type==kOfxParamTypeRGB;}
OfxStatus defineParam(OfxParamSetHandle h,const char*t,const char*n,OfxPropertySetHandle*out){auto a=std::make_unique<Param>();a->name=n;a->type=t;ss(ph(a->props),kOfxParamPropType,0,t);si(ph(a->props),kOfxParamPropEnabled,0,1);si(ph(a->props),kOfxParamPropSecret,0,0);if(a->type!=kOfxParamTypeGroup&&a->type!=kOfxParamTypePage&&a->type!=kOfxParamTypePushButton){si(ph(a->props),kOfxParamPropCanUndo,0,1);si(ph(a->props),kOfxParamPropEvaluateOnChange,0,1);si(ph(a->props),kOfxParamPropPersistant,0,1);}*out=ph(a->props);set(h).params[n]=std::move(a);return kOfxStatOK;}
OfxStatus getHandle(OfxParamSetHandle h,const char*n,OfxParamHandle*out,OfxPropertySetHandle*props){auto it=set(h).params.find(n);if(it==set(h).params.end()){if(out)*out=nullptr;return kOfxStatErrUnknown;}if(out)*out=reinterpret_cast<OfxParamHandle>(it->second.get());if(props)*props=ph(it->second->props);return kOfxStatOK;}
OfxStatus setProps(OfxParamSetHandle h,OfxPropertySetHandle*out){*out=ph(set(h).props);return kOfxStatOK;}
OfxStatus paramProps(OfxParamHandle h,OfxPropertySetHandle*out){*out=ph(param(h).props);return kOfxStatOK;}
OfxStatus readValue(Param&a,va_list args){if(a.type==kOfxParamTypeString){*va_arg(args,char**)=const_cast<char*>(a.text.c_str());return kOfxStatOK;}for(int i=0;i<components(a);i++){double v=i<int(a.values.size())?a.values[i]:0;if(floating(a))*va_arg(args,double*)=v;else *va_arg(args,int*)=int(v);}return kOfxStatOK;}
OfxStatus getValue(OfxParamHandle h,...){va_list a;va_start(a,h);auto s=readValue(param(h),a);va_end(a);return s;}
OfxStatus getAtTime(OfxParamHandle h,OfxTime time,...){va_list a;va_start(a,time);auto s=readValue(param(h),a);va_end(a);return s;}
OfxStatus writeValue(Param&a,va_list args){checkWrite();if(a.type==kOfxParamTypeString){const char*v=va_arg(args,const char*);a.text=v?v:"";return kOfxStatOK;}a.values.resize(components(a));for(auto&v:a.values)v=floating(a)?va_arg(args,double):double(va_arg(args,int));return kOfxStatOK;}
OfxStatus setValue(OfxParamHandle h,...){va_list a;va_start(a,h);auto s=writeValue(param(h),a);va_end(a);return s;}
OfxStatus setAtTime(OfxParamHandle h,OfxTime time,...){va_list a;va_start(a,time);auto s=writeValue(param(h),a);va_end(a);return s;}
OfxStatus numKeys(OfxParamHandle h,unsigned*n){if(hostAction!=kOfxActionInstanceChanged||std::this_thread::get_id()!=hostThread)++illegalKeyReads;*n=param(h).keys;return kOfxStatOK;}
OfxStatus editBegin(OfxParamSetHandle,const char*){checkWrite();++editDepth;++editBegins;return kOfxStatOK;}
OfxStatus editEnd(OfxParamSetHandle){checkWrite();--editDepth;++editEnds;return kOfxStatOK;}
OfxStatus effectProps(OfxImageEffectHandle h,OfxPropertySetHandle*out){*out=ph(reinterpret_cast<Effect*>(h)->props);return kOfxStatOK;}
OfxStatus effectParams(OfxImageEffectHandle h,OfxParamSetHandle*out){*out=reinterpret_cast<OfxParamSetHandle>(&reinterpret_cast<Effect*>(h)->params);return kOfxStatOK;}
OfxStatus clipDefine(OfxImageEffectHandle h,const char*n,OfxPropertySetHandle*out){auto&e=*reinterpret_cast<Effect*>(h);*out=ph(std::string(n)==kOfxImageEffectOutputClipName?e.output:e.source);return kOfxStatOK;}
OfxStatus clipGet(OfxImageEffectHandle h,const char*n,OfxImageClipHandle*out,OfxPropertySetHandle*props){OfxPropertySetHandle a;clipDefine(h,n,&a);if(out)*out=reinterpret_cast<OfxImageClipHandle>(a);if(props)*props=a;return kOfxStatOK;}
OfxStatus clipProps(OfxImageClipHandle h,OfxPropertySetHandle*out){*out=reinterpret_cast<OfxPropertySetHandle>(h);return kOfxStatOK;}
int abortRender(OfxImageEffectHandle){return 0;}
OfxStatus message(void*,const char*,const char*,const char*,...){return kOfxStatOK;}
OfxPropertySuiteV1 properties{};OfxParameterSuiteV1 parameters{};OfxImageEffectSuiteV1 effects{};OfxMessageSuiteV1 messages{};
const void* fetch(OfxPropertySetHandle,const char*n,int version){if(version!=1)return nullptr;if(std::string(n)==kOfxPropertySuite)return &properties;if(std::string(n)==kOfxParameterSuite)return &parameters;if(std::string(n)==kOfxImageEffectSuite)return &effects;if(std::string(n)==kOfxMessageSuite)return &messages;return nullptr;}
void initSuites(){
  properties={sp,ss,sd,si,spn,ssn,sdn,sin,gp,gs,gd,gi,gpn,gsn,gdn,gin,resetProp,dimension};
  parameters.paramDefine=defineParam;parameters.paramGetHandle=getHandle;parameters.paramSetGetPropertySet=setProps;parameters.paramGetPropertySet=paramProps;parameters.paramGetValue=getValue;parameters.paramGetValueAtTime=getAtTime;parameters.paramSetValue=setValue;parameters.paramSetValueAtTime=setAtTime;parameters.paramGetNumKeys=numKeys;parameters.paramEditBegin=editBegin;parameters.paramEditEnd=editEnd;
  effects.getPropertySet=effectProps;effects.getParamSet=effectParams;effects.clipDefine=clipDefine;effects.clipGetHandle=clipGet;effects.clipGetPropertySet=clipProps;effects.abort=abortRender;messages.message=message;
}
void initializeDefaults(Effect&e){for(auto&kv:e.params.params){auto&a=*kv.second;if(a.type==kOfxParamTypeString){char*s=nullptr;gs(ph(a.props),kOfxParamPropDefault,0,&s);a.text=s?s:"";}else{a.values.resize(components(a));for(int i=0;i<components(a);i++){if(floating(a))gd(ph(a.props),kOfxParamPropDefault,i,&a.values[i]);else{int v=0;gi(ph(a.props),kOfxParamPropDefault,i,&v);a.values[i]=v;}}}}}
void require(bool v,const std::string&s){if(!v)throw std::runtime_error(s);std::cout<<"PASS "<<s<<"\n";}
OfxStatus action(OfxPlugin*plug,Effect&e,const char*name,Props*args=nullptr){auto old=hostAction;hostAction=name;auto result=plug->mainEntry(name,&e,args?ph(*args):nullptr,nullptr);hostAction=old;return result;}
void press(OfxPlugin*plug,Effect&e,const char*name){Props args;ss(ph(args),kOfxPropChangeReason,0,kOfxChangeUserEdited);ss(ph(args),kOfxPropName,0,name);ss(ph(args),kOfxPropType,0,kOfxTypeParameter);sd(ph(args),kOfxPropTime,0,0);auto status=action(plug,e,kOfxActionInstanceChanged,&args);require(status==kOfxStatOK||status==kOfxStatReplyDefault,std::string("host action ")+name);}
std::vector<std::string> split(const std::string&s){std::vector<std::string>v;size_t b=0;for(;;){auto e=s.find('\t',b);v.push_back(s.substr(b,e==std::string::npos?e:e-b));if(e==std::string::npos)break;b=e+1;}return v;}
struct Discovery{std::string session,id,gen;unsigned short port=0;bool armed=false;};
SOCKET listener=INVALID_SOCKET;
Discovery discover(bool armedWanted,int timeoutMs=4000,const std::string&except="",std::uint64_t afterGeneration=0){auto end=std::chrono::steady_clock::now()+std::chrono::milliseconds(timeoutMs);char buf[65000];while(std::chrono::steady_clock::now()<end){sockaddr_in from{};int len=sizeof(from);int n=recvfrom(listener,buf,sizeof(buf),0,reinterpret_cast<sockaddr*>(&from),&len);if(n<=0)continue;auto v=split(std::string(buf,n));if(v.size()>=9&&v[0]=="INSTANCE"&&v[3]!=except&&(v[6]=="1")==armedWanted&&std::stoull(v[4])>afterGeneration)return {v[2],v[3],v[4],static_cast<unsigned short>(std::stoi(v[5])),v[6]=="1"};}throw std::runtime_error("No expected INSTANCE discovery; check wire fields and companion port 55051");}
void send(const Discovery&d,const std::string&op,const std::string&tail=""){std::string msg=op+"\t1\t"+d.session+"\t"+d.id+"\t"+d.gen+tail;sockaddr_in dest{};dest.sin_family=AF_INET;dest.sin_addr.s_addr=htonl(INADDR_LOOPBACK);dest.sin_port=htons(d.port);sendto(listener,msg.data(),int(msg.size()),0,reinterpret_cast<sockaddr*>(&dest),sizeof(dest));std::this_thread::sleep_for(std::chrono::milliseconds(100));}
int main(int argc,char**argv){
 try{
  if(argc<2)throw std::runtime_error("Usage: HostHarness.exe path/to/spektrafilm_midi.ofx [regular.ofx]");
  auto temp=std::filesystem::current_path()/".build"/"host-harness-state";std::filesystem::create_directories(temp);_putenv_s("APPDATA",temp.string().c_str());
  const bool serving=argc>2&&std::string(argv[2])=="--serve";
  WSADATA ws;WSAStartup(MAKEWORD(2,2),&ws);listener=socket(AF_INET,SOCK_DGRAM,IPPROTO_UDP);DWORD receiveTimeout=100;setsockopt(listener,SOL_SOCKET,SO_RCVTIMEO,reinterpret_cast<char*>(&receiveTimeout),sizeof(receiveTimeout));sockaddr_in local{};local.sin_family=AF_INET;local.sin_addr.s_addr=htonl(INADDR_LOOPBACK);local.sin_port=htons(serving?0:55051);require(bind(listener,reinterpret_cast<sockaddr*>(&local),sizeof(local))==0,"test discovery port available");
  initSuites();auto dll=LoadLibraryW(std::filesystem::absolute(argv[1]).c_str());require(dll!=nullptr,"load sibling OFX binary");auto entry=reinterpret_cast<OfxPlugin*(*)(int)>(GetProcAddress(dll,"OfxGetPlugin"));require(entry!=nullptr,"OFX export available");auto*plug=entry(0);require(std::string(plug->pluginIdentifier)=="local.tangentmidi.spektrafilm","sibling has independent OFX identity");
  if(argc>2&&!serving){auto regular=LoadLibraryW(std::filesystem::absolute(argv[2]).c_str());require(regular!=nullptr,"regular baseline binary loads alongside sibling");auto getRegular=reinterpret_cast<OfxPlugin*(*)(int)>(GetProcAddress(regular,"OfxGetPlugin"));require(getRegular&&std::string(getRegular(0)->pluginIdentifier)!=plug->pluginIdentifier,"regular ID remains distinct");FreeLibrary(regular);}
  Props hostProps;OfxHost host{ph(hostProps),fetch};plug->setHost(&host);Effect effect;require(action(plug,effect,kOfxActionLoad)==kOfxStatOK,"fetch host suites");require(action(plug,effect,kOfxActionDescribe)==kOfxStatOK,"describe sibling");Props context;ss(ph(context),kOfxImageEffectPropContext,0,kOfxImageEffectContextFilter);require(action(plug,effect,kOfxImageEffectActionDescribeInContext,&context)==kOfxStatOK,"define parameter descriptors");initializeDefaults(effect);require(action(plug,effect,kOfxActionCreateInstance)==kOfxStatOK,"create MIDI instance");
  require(effect.params.params.count("midiArm")&&effect.params.params.count("midiApply"),"controller host buttons exist");
  const auto descriptorFlag=[&](const char*name,const char*property,int expected){int flag=-1;return gi(ph(effect.params.params.at(name)->props),property,0,&flag)==kOfxStatOK&&flag==expected;};
  for(const char*name:{"midiStatus","midiTarget","midiBuildNotice"})require(descriptorFlag(name,kOfxParamPropCanUndo,0)&&descriptorFlag(name,kOfxParamPropEvaluateOnChange,0)&&descriptorFlag(name,kOfxParamPropPersistant,0),std::string(name)+" status is transient, non-undoable and non-evaluating");
  for(const char*name:{"midiArm","midiDisarm","midiApply"})require(descriptorFlag(name,kOfxParamPropCanUndo,0)&&descriptorFlag(name,kOfxParamPropEvaluateOnChange,0)&&descriptorFlag(name,kOfxParamPropPersistant,0),std::string(name)+" management descriptor requests no undo/render state");
  require(descriptorFlag("filmExposureEv",kOfxParamPropCanUndo,1)&&descriptorFlag("filmExposureEv",kOfxParamPropEvaluateOnChange,1)&&descriptorFlag("hdrPeakNits",kOfxParamPropCanUndo,1),"actual numeric grading parameters remain undoable and evaluating");
  // This suite owns its redirected APPDATA fixture. Reset its saved defaults
  // through the normal host action so repeated runs start from a known state.
  if(!serving)press(plug,effect,"resetDefaults");
  press(plug,effect,"midiArm");auto&exposure=*effect.params.params.at("filmExposureEv");double old=exposure.values[0];
  if(serving){
    // Synthetic host supplies legal button actions; tests the real C#→UDP→DLL
    // path without suggesting that Resolve has an equivalent event pump.
    auto until=std::chrono::steady_clock::now()+std::chrono::seconds(9);
    while(std::chrono::steady_clock::now()<until){Props args;ss(ph(args),kOfxPropChangeReason,0,kOfxChangeUserEdited);ss(ph(args),kOfxPropName,0,"midiApply");sd(ph(args),kOfxPropTime,0,0);action(plug,effect,kOfxActionInstanceChanged,&args);std::this_thread::sleep_for(std::chrono::milliseconds(100));}
    require(exposure.values[0]>old,"end-to-end companion OSC input reaches native host-owned exposure");require(illegalWrites==0&&illegalKeyReads==0,"end-to-end edits obey host action boundaries");action(plug,effect,kOfxActionDestroyInstance);action(plug,effect,kOfxActionUnload);FreeLibrary(dll);closesocket(listener);WSACleanup();return 0;
  }
  auto d=discover(true);
  send(d,"DELTA","\tfilmExposureEv\t0\t1");require(exposure.values[0]==old,"background receiver never mutates OFX parameters");press(plug,effect,"midiApply");require(exposure.values[0]>old,"queued movement applied through valid host action");
  send(d,"SET","\tfilmExposureEv\t0\t999");press(plug,effect,"midiApply");require(exposure.values[0]<=8.0,"controller clamps parameter bounds");
  exposure.keys=1;double keyed=exposure.values[0];send(d,"DELTA","\tfilmExposureEv\t0\t-1");press(plug,effect,"midiApply");require(exposure.values[0]==keyed,"animated parameter is not flattened");exposure.keys=0;press(plug,effect,"filmExposureEv");
  send(d,"RESET","\tfilmExposureEv\t0");press(plug,effect,"midiApply");require(std::abs(exposure.values[0])<1e-8,"reset uses host descriptor default");

  auto value=[&](const char*name){return effect.params.params.at(name)->values.at(0);};
  send(d,"SET","\toutputRole\t0\t1");press(plug,effect,"midiApply");require(value("outputRole")==1,"controller enables HDR parameter bank");
  send(d,"SET","\thdrPreset\t0\t1");press(plug,effect,"midiApply");
  require(value("hdrPreset")==1&&value("hdrTransfer")==0&&value("hdrReferenceWhiteNits")==203&&value("hdrPeakNits")==4000&&value("hdrToneMapping")==1,"HDR preset applies all linked values");
  send(d,"SET","\thdrPeakNits\t0\t1500");press(plug,effect,"midiApply");require(value("hdrPeakNits")==1500&&value("hdrPreset")==3,"manual HDR controller edit selects Custom preset");
  auto&peak=*effect.params.params.at("hdrPeakNits");peak.keys=1;press(plug,effect,"hdrPeakNits");
  send(d,"SET","\thdrPreset\t0\t2");press(plug,effect,"midiApply");
  require(value("hdrPreset")==3&&value("hdrPeakNits")==1500&&value("hdrTransfer")==0,"linked animated HDR parameter blocks preset mutation");
  peak.keys=0;press(plug,effect,"hdrPeakNits");send(d,"SET","\thdrPreset\t0\t0");press(plug,effect,"midiApply");send(d,"SET","\toutputRole\t0\t0");press(plug,effect,"midiApply");
  require(value("outputRole")==0&&value("hdrPreset")==0&&value("hdrPeakNits")==1000,"HDR fixture restored before defaults are saved");

  const double internalBefore=value("dirUsesStockCalibration");send(d,"SET","\tdirUsesStockCalibration\t0\t0");press(plug,effect,"midiApply");require(value("dirUsesStockCalibration")==internalBefore,"hidden internal calibration flag rejects controller writes");
  si(ph(exposure.props),kOfxParamPropIsAnimating,0,1);press(plug,effect,"filmExposureEv");send(d,"DELTA","\tfilmExposureEv\t0\t1");press(plug,effect,"midiApply");require(value("filmExposureEv")==0,"expression-driven parameter rejects controller writes");si(ph(exposure.props),kOfxParamPropIsAnimating,0,0);press(plug,effect,"filmExposureEv");

  // Keep the connection alive while deliberately leaving one command queued
  // beyond its two-second TTL. This distinguishes stale input from disarming.
  send(d,"DELTA","\tfilmExposureEv\t0\t1");std::this_thread::sleep_for(std::chrono::milliseconds(1100));send(d,"SNAPSHOT");std::this_thread::sleep_for(std::chrono::milliseconds(1100));press(plug,effect,"midiApply");require(value("filmExposureEv")==0,"expired queued movement cannot apply later");send(d,"DELTA","\tfilmExposureEv\t0\t0.5");press(plug,effect,"midiApply");require(value("filmExposureEv")==0.5,"heartbeat preserves target while stale queue is discarded");send(d,"RESET","\tfilmExposureEv\t0");press(plug,effect,"midiApply");
  Effect second;require(action(plug,second,kOfxImageEffectActionDescribeInContext,&context)==kOfxStatOK,"describe second instance");initializeDefaults(second);require(action(plug,second,kOfxActionCreateInstance)==kOfxStatOK,"create second instance");press(plug,second,"midiArm");auto d2=discover(true,4000,d.id);send(d,"DELTA","\tfilmExposureEv\t0\t1");press(plug,effect,"midiApply");require(std::abs(exposure.values[0])<1e-8,"arming second instance revokes first target");send(d2,"SET","\tfilmExposureEv\t0\t-2");press(plug,second,"midiApply");require(second.params.params.at("filmExposureEv")->values[0]==-2,"movement reaches only second armed instance");
  send(d2,"DISARM");std::this_thread::sleep_for(std::chrono::milliseconds(150));send(d2,"DELTA","\tfilmExposureEv\t0\t1");press(plug,second,"midiApply");require(second.params.params.at("filmExposureEv")->values[0]==-2,"stale generation/disarmed commands cannot edit");
  press(plug,second,"midiArm");auto liveSecond=discover(true,4000,d.id,std::stoull(d2.gen));send(liveSecond,"DELTA","\tfilmExposureEv\t0\t1");std::this_thread::sleep_for(std::chrono::milliseconds(3300));auto timedOut=discover(false,4000,d.id,std::stoull(liveSecond.gen));require(timedOut.id==liveSecond.id,"missing companion heartbeat disarms and advances generation");send(liveSecond,"SET","\tfilmExposureEv\t0\t6");press(plug,second,"midiApply");require(second.params.params.at("filmExposureEv")->values[0]==-2,"timeout drops queued and stale-generation movement");
  press(plug,effect,"saveDefaults");require(std::filesystem::exists(temp/"TangentMidi"/"Spektrafilm"/"v1"/"ofx-defaults-v1.spkdefaults"),"MIDI defaults use isolated state namespace");require(!std::filesystem::exists(temp/"spektrafilm"/"ofx-defaults-v1.spkdefaults"),"regular defaults remain untouched");
  require(editDepth==0&&editBegins==editEnds&&editBegins>0,"OFX edit groups are balanced");require(illegalWrites==0,"all setters run on host thread in allowed actions");require(illegalKeyReads==0,"key enumeration only occurs in InstanceChanged");require(action(plug,second,kOfxActionDestroyInstance)==kOfxStatOK,"second instance unregisters");require(action(plug,effect,kOfxActionDestroyInstance)==kOfxStatOK,"instance unregisters on destruction");
  action(plug,effect,kOfxActionUnload);FreeLibrary(dll);closesocket(listener);WSACleanup();std::cout<<"Host contract tests passed; Resolve acceptance remains required.\n";return 0;
 }catch(const std::exception&e){std::cerr<<"FAIL "<<e.what()<<"\n";return 1;}
}
