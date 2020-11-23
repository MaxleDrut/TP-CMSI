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

float turbulence(in vec2 p, in float amplitude, in float fbase, in float attenuation, in int noctave) {
    int i;
    float res = .0;
    float f = fbase;
    for (i=0;i<noctave;i++) {
        res = res+amplitude*noise(f*p);
        amplitude = amplitude*attenuation;
        f = f*2.;
    }
    return res;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float objLongueur = 12.0;
    float freqBase = objLongueur/iResolution.x;
    float vPix = 0.5 + 0.5*turbulence(fragCoord,1.0,freqBase,0.5,6);
    //Noise renvoie des valeurs entre -1 et +1, on convertit entre 0 et 1
    vec3 col = vec3(vPix,vPix,vPix);
    
    fragColor = vec4(col,1.0);
}

