#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue May 21 13:05:49 2024

@author: agl4001
"""

import altair as alt
import pandas as pd

df = pd.read_csv("PrimateMGA-MEME-ImputedStates.csv")
                 
      
source = df

source = source.astype({"HumanSite": int, "ObservedSupport": float, "ImputedCodon": str})

chart = alt.Chart(source, title="Primate-MGA Evolutionary State Imputation").mark_point().encode(
    x=alt.X('HumanSite'),
    y=alt.Y('ImputedCodon:N'),
    color=alt.Color('ImputedSupport:Q').scale(scheme='greenblue'),
    tooltip=[
        alt.Tooltip("HumanSite", title="Human codon site"),
        alt.Tooltip("ImputedCodon", title="Imputed Codon"),
        alt.Tooltip("ImputedSupport", title="Imputed Support"),
        alt.Tooltip("ObservedCodon", title="Observed Codon"),
        alt.Tooltip("ObservedSupport", title="Observed Support"),
    ],
    #size=alt.Color('ImputedSupport:Q')
).properties(
    width=1200,
    height=800
).configure_view(
    step=13,
    strokeWidth=0
).configure_axis(
    domain=False
)
    
chart2 = alt.Chart(source, title="Primate-MGA Evolutionary State Imputation").mark_point().encode(
    x=alt.X('HumanSite'),
    y=alt.Y('ObservedCodon'),
    color=alt.Color('Observedupport:Q').scale(scheme='greenblue'),
    tooltip=[
        alt.Tooltip("HumanSite", title="Human codon site"),
        alt.Tooltip("ObservedCodon", title="Observed Codon"),
        alt.Tooltip("ObservedSupport", title="Observed Support"),
    ],
    #size=alt.Color('ImputedSupport:Q')
).properties(
    width=1200,
    height=800
).configure_view(
    step=13,
    strokeWidth=0
).configure_axis(
    domain=False
)

chart.save('chart.html')