#include<bits/stdc++.h>
using namespace std;
int main(){
    /*
    string s;
    int i=0;
    vector<string> v;
    while(cin>>s){
        v.push_back(s);
        //cout<<i<<" "<<s<<'\n';
        i++;
        if(i==64) break;
    }
    for(int j=0;j<v.size();j++){
      //  cout<<"4'd"<<j%16<<": k <= 32'h"<<v[j]<<";"<<endl;*/
//        cout<<"4'd0:"<<j<<" "<<v[j]<<endl;
    int ans;
    for(int i=0;i<64;i++){
        if(i<16) ans=i;
        else if(i<32) ans=(5*i+1)%16;
        else if(i<48) ans=(3*i+5)%16;
        else ans=(7*i)%16; 
        cout<<"4'd"<<i%16<<": g <= 4'd"<<ans<<";\n";
//        cout<<i<<" "<<ans<<endl;
    }
}
/*
        uint32_t i;
		for(i = 0; i < 64; i++)
        {
            uint32_t f, g;

             if (i < 16) {
                f = (b & c) | ((~b) & d);
                g = i;
            } else if (i < 32) {
                f = (d & b) | ((~d) & c);
                g = (5*i + 1) % 16;
            } else if (i < 48) {
                f = b ^ c ^ d;
                g = (3*i + 5) % 16;          
            } else {
                f = c ^ (b | (~d));
                g = (7*i) % 16;
            }

*/