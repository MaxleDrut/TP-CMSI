const int Steps = 1000;
const float Epsilon = 0.01; // Marching epsilon
const float T=0.05;

const float rA=1.0; // Minimum ray marching distance from origin
const float rB=50.0; // Maximum

const float freqTerrain = 0.25;
const float lissage = 0.35;
const float ampli = 1.7;
const int oct = 10;

const float nivMer = -0.80; //y en desosus duquel c'est l'océan

vec2 hash( vec2 p ) 
{
	p = vec2( dot(p,vec2(127.1,311.7)),
			  dot(p,vec2(269.5,183.3)) );

	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec2 p )
{
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

	vec2 i = floor( p + (p.x+p.y)*K1 );
	
    vec2 a = p - i + (i.x+i.y)*K2;
    vec2 o = step(a.yx,a.xy);    
    vec2 b = a - o + K2;
	vec2 c = a - 1.0 + 2.0*K2;

    vec3 h = max( 0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );

	vec3 n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));

    return dot( n, vec3(70.0) );
}

float ridged(in vec2 p) {
  return 2.0*(0.5 - abs(0.5-noise(p)));   
}


float turbulence(in vec2 p, in float amplitude, in float fbase, in float attenuation, in int noctave) {
    int i;
    float res = .0;
    float f = fbase;
    for (i=0;i<noctave;i++) {
        res = res+amplitude*ridged(f*p);
        amplitude = amplitude*attenuation;
        f = f*2.;
    }
    return res;
}


// Transforms
vec3 rotateY(vec3 p, float a)
{
   float oldX = p.x;
   p.x = p.z*sin(a)+p.x*cos(a);
   p.z = p.z*cos(a)-oldX*sin(a);
   return p;
}

// Smooth falloff function
// r : small radius
// R : Large radius
float falloff( float r, float R )
{
   float x = clamp(r/R,0.0,1.0);
   float y = (1.0-x*x);
   return y*y*y;
}

// Primitive functions

// Point skeleton
// p : point
// c : center of skeleton
// e : energy associated to skeleton
// R : large radius
float point(vec3 p, vec3 c, float e,float R)
{
   return e*falloff(length(p-c),R);
}


// Blending
// a : field function of left sub-tree
// b : field function of right sub-tree
float Blend(float a,float b)
{
   return a+b;
}

// Potential field of the object
// p : point
float object(vec3 p, out float dY)
{
   vec2 plan = vec2(p.z,p.x);
   float hauteur = 0.5*turbulence(plan, ampli, freqTerrain, lissage , oct) - 0.5;
    
   if(hauteur < nivMer) { //hauteur est entre 0 et -1
       dY = nivMer - hauteur;
       hauteur = nivMer;
   } else {
       dY=-1.0;
   }
   
   return hauteur-p.y;
}

// Calculate object normal
// p : point
vec3 ObjectNormal(in vec3 p, out float trash)
{
   float eps = 0.0001;
   vec3 n;
   float v = object(p,trash);
   n.x = object( vec3(p.x+eps, p.y, p.z),trash ) - v;
   n.y = object( vec3(p.x, p.y+eps, p.z),trash ) - v;
   n.z = object( vec3(p.x, p.y, p.z+eps),trash ) - v;
   return normalize(n);
}

// Trace ray using ray marching
// o : ray origin
// u : ray direction
// h : hit
// s : Number of steps
//dY : necessaire pour calculer la différence de profondeur p/r au hachage

float Trace(vec3 o, vec3 u, out bool h,out int s, out float dY)
{
   h = false;

   // Don't start at the origin
   // instead move a little bit forward
   float t=rA;

   for(int i=0; i<Steps; i++)
   {
      s=i;
      vec3 p = o+t*u;
      float v = object(p,dY);
      // Hit object (1) 
      if (v > 0.0)
      {
         s=i;
         h = true;
         break;
      }
      // Move along ray
      t += max(Epsilon,-v/2.0);

      // Escape marched far away
      if (t>rB)
      {
         break;
      }
   }
   return t;
}

// Background color
vec3 background(vec3 rd)
{
    float facteurJour = 1.0;
    if(sin(iTime)<0.2) {
        facteurJour = (sin(iTime)-0.2)+1.0;
    }
   return facteurJour*mix(vec3(0.8, 0.8, 0.9), vec3(0.6, 0.9, 1.0), rd.y*1.0+0.25);
}

// Shading and lighting
// p : point,
// n : normal at point
vec3 Shade(vec3 p, vec3 n, int s, float deltaY)
{
   int inter = 200; 
   int largeur = 10;
    
   int pCent = int (p.y*1000.0)+1000;
   vec3 c;
    
    if(pCent%inter < largeur && deltaY < 0.0) {
      c = vec3(0.3,0.3,0.3);  
    } else {
       //Calcul position du soleil
       
       float time = iTime; 
		float coefNuit = 1.0;
        
		vec3 lightPos;
        if(sin(time)>=0.0) {
          lightPos = vec3(10.0*cos(time),0.8,10.0);
          coefNuit = 0.6*sin(time)+0.4;
        } else {
          coefNuit = 0.4+sin(time)*0.2;
          lightPos = vec3(10.0*cos(time),0.5*sin(time),0.0);
        }
       //lightPos = vec3(-10.0*sin(time),-nivMer+1.0,10.0);
           
       vec3 lightColor = vec3(1.765, 1.765, 1.765); //Les cimes sont couleur gris très clair
       
       //Hachage turbulence des couleurs montagnes :
       vec2 plan = vec2(p.z,p.x);
   	   float turbuY = 0.20*turbulence(plan,1.2, 5.0, 0.8, 4);
        
       p.y = p.y+turbuY*p.y; //Réadaptation aléatoire de y selon le hachage
       
       //turbuY = 0.0;
        if(deltaY>=0.0) {
            if(deltaY<=0.6) {
            	lightColor.x = 2.0*(-81.7*deltaY+51.0)/255.0;
           		lightColor.y = 2.0*(-166.66*deltaY+102.0)/255.0;
            	lightColor.z = 2.0*(-305.25*deltaY+255.0)/255.0;  
            } else {
                lightColor.x = 2.0*2.0/255.0;
           		lightColor.y = 2.0*2.0/255.0;
            	lightColor.z = 2.0*72.0/255.0;  
            }
        } else if(p.y<=0.0 && p.y>=-0.5) {        
            lightColor.x = 2.0*(300.0*p.y+225.0)/255.0;
            lightColor.y = 2.0*(348.0*p.y+225.0)/255.0;
            lightColor.z = 2.0*(400.0*p.y+225.0)/255.0;
        } else if(p.y<=-0.5){   
            lightColor.x = 2.0*(86.0*p.y+118.0)/255.0;
            lightColor.y = 2.0*(84.0*p.y+93.0)/255.0;
            lightColor.z = 2.0*(32.0*p.y+41.0)/255.0;
        }

       /* if(angle<-0.8) {
         	lightColor.x = 2.0;
            lightColor.y = 0.0;
            lightColor.z = 0.0;
        }*/
       vec3 l = normalize(lightPos - p);
	
       // Not even Phong shading, use weighted cosine instead for smooth transitions
       float diff = 0.5*(1.0+dot(n, l));
		lightColor = lightColor*coefNuit;
       c =  0.5*vec3(0.5,0.5,0.5)+0.5*diff*lightColor;
       float fog = 0.7*float(s)/(float(Steps-1));
       c = (1.0-fog)*c+fog*vec3(1.0,1.0,1.0);
    }
   return c;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
   vec2 pixel = (gl_FragCoord.xy / iResolution.xy)*2.0-1.0;

   // compute ray origin and direction
   float asp = iResolution.x / iResolution.y;
   vec3 rd = vec3(asp*pixel.x, pixel.y, -2.0);
   vec3 ro = vec3(0.0, 0.0, 15.0);
  
   vec2 mouse = iMouse.xy / iResolution.xy;
   float a=-mouse.x;
   rd.z = rd.z+2.0*mouse.y;
   rd = normalize(rd);
   ro = rotateY(ro, a);
   rd = rotateY(rd, a);

   // Trace ray
   bool hit;
    
   float deltaY;

   float trash; //Pour pas salir delta Y;
   // Number of steps
   int s;

   float t = Trace(ro, rd, hit,s, deltaY);
   vec3 pos=ro+t*rd;
   // Shade background
   vec3 rgb = background(rd);

   if (hit)
   {
      // Compute normal
      vec3 n = ObjectNormal(pos,trash);

      // Shade object with light
      rgb = Shade(pos, n, s,deltaY);
   }

   fragColor=vec4(rgb, 1.0);
}
