#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue May 21 13:05:49 2024

@author: agl4001
"""

import altair as alt
import pandas as pd

#df = pd.read_csv("PrimateMGA-MEME-ImputedStates.csv")
df = pd.read_csv("MammalianMGA-MEME-ImputedStates.csv")
tag = "Mammalian"               
      
source = df

source = source.astype({"HumanSite": int, "Support": float, "ImputedCodon": str})

# the shape of a hexagon
hexagon = "M0,-2.3094010768L2,-1.1547005384 2,1.1547005384 0,2.3094010768 -2,1.1547005384 -2,-1.1547005384Z"

chart = alt.Chart(source, title=tag+"-MGA Evolutionary State Imputation").mark_point(size=50, shape=hexagon).encode(
    x=alt.X('HumanSite'),
    y=alt.Y('ImputedCodon:N', axis=alt.Axis(tickCount=4)),
    color=alt.Color('ImputedCodon:O'),
    tooltip=[
        alt.Tooltip("HumanSite", title="Human codon site"),
        alt.Tooltip("ImputedCodon", title="Imputed Codon"),
        alt.Tooltip("ImputedSupport", title="Imputed Support"),
        alt.Tooltip("ObservedCodon", title="Observed Codon"),
        alt.Tooltip("Support", title="Support"),
    ],
    #size=alt.Size('ImputedSupport:Q')
    fill=alt.Color('ImputedSupport:Q').scale(scheme='darkblue'),
).properties(
    width=1600,
    height=800
)
    
"""
chart2 = alt.Chart(source, title=tag+"-MGA Evolutionary State Imputation").mark_bar().encode(
    x=alt.X('HumanSite'),
    y=alt.Y('ObservedCodon:O'),
    color=alt.Color('ObservedCodon'),
    tooltip=[
        alt.Tooltip("HumanSite", title="Human codon site"),
        alt.Tooltip("ObservedCodon", title="Observed Codon"),
        alt.Tooltip("ObservedSupport", title="Observed Support"),
    ],
    #size=alt.Color('ImputedSupport:Q')
).properties(
    width=1200,
    height=800
)
"""

alt.vconcat(chart).configure_view(
    step=1,
    strokeWidth=0
).configure_axis(
    domain=False
).interactive().save(tag+'_update_chart_2.html')