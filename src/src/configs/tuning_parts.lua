return [[
{
    "tuningParts": {
        "afterburner": {
            "attachment": {
                "node": "chassis",
                "scale": 0.015,
                "source": "textures/tuneparts/afterburner.png",
                "type": "sprite"
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Power boost with higher fuel consumption"
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "BOOST"
                    },
                    "stat": {
                        "from": 42.5,
                        "to": 75.0
                    },
                    "masteryPowerBoost": true
                },
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "TOP SPEED"
                    },
                    "stat": {
                        "from": 2.5,
                        "to": 3.5
                    },
                    "masteryPowerBoost": true
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": 2.5,
                        "to": 3.5
                    },
                    "effect": "maxSpeed",
                    "type": "engine-params"
                },
                {
                    "amount": {
                        "from": 42.5,
                        "to": 75.0
                    },
                    "type": "acceleration"
                },
                {
                    "amount": 3.0,
                    "type": "fuel-consumption"
                },
                {
                    "effect": "afterburner",
                    "offset": [
                        0.305,
                        0.413
                    ],
                    "type": "particle"
                },
                {
                    "effect": "afterburner",
                    "type": "audio"
                }
            ],
            "icon": "textures/tuneparts/afterburner.png",
            "name": {
                "localize": "Name of tuning part, keep it short. Gives greater thrust and speed in exchange for higher fuel consumption.",
                "value": "AFTERBURNER"
            },
            "partType": "afterburner",
            "category": "afterburner",
            "echoBehavior": "last-active-duration",
            "echoDurationCap": 5.0,
            "rarity": "epic",
            "requireAllTriggersStopToReset": false,
            "triggers": {
                "accelerate": {},
                "fuel": {
                    "direction": 1,
                    "threshold": 0.001
                }
            }
        },
        "echo": {
            "attachment": {
                "node": "chassis",
                "scale": 0.015,
                "source": "textures/tuneparts/echo.png",
                "type": "sprite"
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Repeats the first equipped tuning part effect after a short delay."
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "ECHO POWER"
                    },
                    "stat": "60+20*x",
                    "masteryPowerBoost": true
                },
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "DELAY"
                    },
                    "stat": 0.8
                }
            ],
            "effects": [
                {
                    "type": "echo",
                    "amount": "0.6+0.2*x",
                    "speed": 0.8,
                    "passive": true
                }
            ],
            "icon": "textures/tuneparts/echo.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "ECHO"
            },
            "partType": "echo",
            "category": "echo",
            "rarity": "mythic",
            "targetShader": "tune_echo"
        },
        "amplifier": {
            "attachment": {
                "node": "chassis",
                "scale": 0.015,
                "source": "textures/tuneparts/amp.png",
                "type": "sprite"
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Boosts the power of other equipped tuning parts."
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "PART POWER"
                    },
                    "stat": {
                        "from": 10.0,
                        "to": 20.0
                    },
                    "masteryPowerBoost": true
                }
            ],
            "icon": "textures/tuneparts/amp.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "AMPLIFIER"
            },
            "partType": "amplifier",
            "category": "amplifier",
            "rarity": "mythic",
            "tuningPartPowerMultiplier": {
                "from": 1.1,
                "to": 1.2
            },
            "targetShader": "tune_amplifier"
        },
        "air_control": {
            "attachment": {
                "node": "chassis",
                "scale": 0.015,
                "source": "textures/tuneparts/aircontrol.png",
                "type": "sprite"
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Turn faster in air."
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Amount of braking force",
                        "value": "AIR CONTROL"
                    },
                    "stat": {
                        "from": 13.0,
                        "to": 20.0
                    },
                    "masteryPowerBoost": true
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": 1.0,
                        "to": 1.0
                    },
                    "curve": {
                        "from": 0.0,
                        "to": 0.25
                    },
                    "type": "air-control"
                },
                {
                    "amount": {
                        "from": 1.3,
                        "to": 2.0
                    },
                    "passive": true,
                    "type": "max-angular-velocity"
                }
            ],
            "icon": "textures/tuneparts/aircontrol.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "AIR CONTROL"
            },
            "partType": "air_control",
            "category": "air_control",
            "rarity": "common",
            "triggers": {
                "air-time": {
                    "direction": 1,
                    "threshold": 0.1
                }
            }
        },
        "air_control_racing_truck": {
            "attachment": {
                "node": "chassis",
                "scale": 0.015,
                "source": "textures/tuneparts/aircontrol.png",
                "type": "sprite"
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Turn faster in air."
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Amount of braking force",
                        "value": "AIR CONTROL"
                    },
                    "stat": {
                        "from": 9.0,
                        "to": 17.0
                    }
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": 1.0,
                        "to": 1.0
                    },
                    "curve": {
                        "from": 0.0,
                        "to": 0.25
                    },
                    "type": "air-control"
                },
                {
                    "amount": {
                        "from": 0.9,
                        "to": 1.7
                    },
                    "passive": true,
                    "type": "max-angular-velocity"
                }
            ],
            "icon": "textures/tuneparts/aircontrol.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "AIR CONTROL"
            },
            "partType": "air_control_racing_truck",
            "category": "air_control",
            "rarity": "common",
            "triggers": {
                "air-time": {
                    "direction": 1,
                    "threshold": 0.1
                }
            }
        },
        "coin_boost": {
            "attachment": {
                "anchor": [
                    0.715,
                    0.524
                ],
                "node": "chassis",
                "scale": 0.01,
                "source": "textures/tuneparts/coinboost.png",
                "type": "sprite",
                "zOrder": 300
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Power boost when collecting coins."
            },
            "effectDuration": {
                "from": 0.5,
                "to": 1.0
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "TOP SPEED"
                    },
                    "stat": {
                        "from": 8.0,
                        "to": 20.0
                    },
                    "masteryPowerBoost": true
                },
                {
                    "name": {
                        "localize": "Duration of tuning part effect",
                        "value": "DURATION"
                    },
                    "stat": {
                        "from": 0.5,
                        "to": 1.0
                    }
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": 2.0,
                        "to": 3.0
                    },
                    "type": "impulse"
                },
                {
                    "amount": {
                        "from": 7.5,
                        "to": 10.0
                    },
                    "effect": "maxSpeed",
                    "type": "engine-params"
                },
                {
                    "effect": "coin-boost",
                    "type": "audio"
                },
                {
                    "effect": "speed",
                    "offset": [
                        0.0746,
                        0.498
                    ],
                    "type": "particle"
                }
            ],
            "icon": "textures/tuneparts/coinboost.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "COIN BOOST"
            },
            "partType": "coin_boost",
            "category": "coin_boost",
            "echoBehavior": "after-stop",
            "rarity": "legendary",
            "triggers": {
                "collect-item": {
                    "oneshot": true,
                    "type": "coin"
                }
            }
        },
        "coin_boost_superbike": {
            "attachment": {
                "anchor": [
                    0.715,
                    0.524
                ],
                "node": "chassis",
                "scale": 0.01,
                "source": "textures/tuneparts/coinboost.png",
                "type": "sprite",
                "zOrder": 300
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Power boost when collecting coins."
            },
            "effectDuration": {
                "from": 0.5,
                "to": 1.0
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "TOP SPEED"
                    },
                    "stat": {
                        "from": 8.0,
                        "to": 20.0
                    }
                },
                {
                    "name": {
                        "localize": "Duration of tuning part effect",
                        "value": "DURATION"
                    },
                    "stat": {
                        "from": 0.5,
                        "to": 1.0
                    }
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": 1.0,
                        "to": 1.5
                    },
                    "type": "impulse"
                },
                {
                    "amount": {
                        "from": 7.5,
                        "to": 10.0
                    },
                    "effect": "maxSpeed",
                    "type": "engine-params"
                },
                {
                    "effect": "coin-boost",
                    "type": "audio"
                },
                {
                    "effect": "speed",
                    "offset": [
                        0.0746,
                        0.498
                    ],
                    "type": "particle"
                }
            ],
            "icon": "textures/tuneparts/coinboost.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "COIN BOOST"
            },
            "partType": "coin_boost_superbike",
            "category": "coin_boost",
            "echoBehavior": "after-stop",
            "rarity": "legendary",
            "triggers": {
                "collect-item": {
                    "oneshot": true,
                    "type": "coin"
                }
            }
        },
        "coin_magnet": {
            "attachment": {
                "anchor": [
                    0.7,
                    0.1
                ],
                "node": "chassis",
                "scale": 0.01,
                "source": "textures/tuneparts/magnet_coins.png",
                "type": "sprite"
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Collect coins with wider radius."
            },
            "effects": [
                {
                    "effect": "coin-magnet",
                    "type": "audio"
                },
                {
                    "effect": "coin-magnet",
                    "offset": [
                        0.494,
                        0.719
                    ],
                    "type": "particle"
                }
            ],
            "icon": "textures/tuneparts/magnet_coins.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "COIN MAGNET"
            },
            "partType": "coin_magnet",
            "category": "coin_magnet",
            "rarity": "common",
            "triggers": {
                "collectible-magnet": {
                    "force": {
                        "from": 20.0,
                        "to": 35.0
                    },
                    "radius": {
                        "from": 5.0,
                        "to": 15.0
                    }
                }
            }
        },
        "flip_speed_boost": {
            "attachment": {
                "anchor": [
                    0.68,
                    0.8
                ],
                "node": "chassis",
                "scale": 0.015,
                "source": "textures/tuneparts/flip-boost.png",
                "type": "sprite"
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Power boost after successful flips."
            },
            "effectDuration": {
                "from": 0.5,
                "to": 1.0
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "BOOST"
                    },
                    "stat": {
                        "from": 250.0,
                        "to": 400.0
                    },
                    "masteryPowerBoost": true
                },
                {
                    "name": {
                        "localize": "Duration of tuning part effect",
                        "value": "DURATION"
                    },
                    "stat": {
                        "from": 0.5,
                        "to": 1.0
                    }
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": 250.0,
                        "to": 400.0
                    },
                    "type": "acceleration"
                },
                {
                    "effect": "flip-boost",
                    "type": "audio"
                },
                {
                    "effect": "particles/exhaust_smoke.plist",
                    "type": "particle"
                },
                {
                    "effect": "boost",
                    "type": "particle"
                }
            ],
            "icon": "textures/tuneparts/flip-boost.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "FLIP BOOST"
            },
            "partType": "flip_speed_boost",
            "category": "flip_speed_boost",
            "echoBehavior": "after-stop",
            "rarity": "rare",
            "triggers": {
                "air-time": {
                    "direction": -1,
                    "threshold": 0.5
                },
                "flip": {
                    "direction": 1,
                    "oneshot": true,
                    "threshold": 0.5
                }
            }
        },
        "fuel_boost": {
            "attachment": {
                "anchor": [
                    0.419,
                    0.475
                ],
                "node": "chassis",
                "scale": 0.01,
                "source": "textures/tuneparts/tunepart_NOS.png",
                "type": "sprite"
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Power boost on collected fuel canister."
            },
            "effectDuration": {
                "from": 0.5,
                "to": 1.0
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "BOOST"
                    },
                    "stat": {
                        "from": 400.0,
                        "to": 400.0
                    },
                    "masteryPowerBoost": true
                },
                {
                    "name": {
                        "localize": "Duration of tuning part effect",
                        "value": "DURATION"
                    },
                    "stat": {
                        "from": 0.5,
                        "to": 1.0
                    }
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": 8.0,
                        "to": 8.0
                    },
                    "type": "impulse"
                },
                {
                    "amount": {
                        "from": 400.0,
                        "to": 400.0
                    },
                    "type": "acceleration"
                },
                {
                    "effect": "fuel-boost",
                    "type": "audio"
                },
                {
                    "effect": "particles/exhaust_smoke.plist",
                    "offset": [
                        -0.0269,
                        0.708
                    ],
                    "type": "particle"
                },
                {
                    "effect": "boost",
                    "offset": [
                        0.136,
                        0.603
                    ],
                    "type": "particle"
                }
            ],
            "icon": "textures/tuneparts/tunepart_NOS.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "FUEL BOOST"
            },
            "partType": "fuel_boost",
            "category": "fuel_boost",
            "echoBehavior": "after-stop",
            "rarity": "legendary",
            "triggers": {
                "collect-item": {
                    "oneshot": true,
                    "type": "fuel",
                    "canBeStartedWhileActive": true
                }
            }
        },
        "fuel_boost_superbike": {
            "attachment": {
                "anchor": [
                    0.419,
                    0.475
                ],
                "node": "chassis",
                "scale": 0.01,
                "source": "textures/tuneparts/tunepart_NOS.png",
                "type": "sprite"
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Power boost on collected fuel canister."
            },
            "effectDuration": {
                "from": 0.5,
                "to": 1.0
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "BOOST"
                    },
                    "stat": {
                        "from": 400.0,
                        "to": 400.0
                    }
                },
                {
                    "name": {
                        "localize": "Duration of tuning part effect",
                        "value": "DURATION"
                    },
                    "stat": {
                        "from": 0.5,
                        "to": 1.0
                    }
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": 4.0,
                        "to": 4.0
                    },
                    "type": "impulse"
                },
                {
                    "amount": {
                        "from": 200.0,
                        "to": 200.0
                    },
                    "type": "acceleration"
                },
                {
                    "effect": "fuel-boost",
                    "type": "audio"
                },
                {
                    "effect": "particles/exhaust_smoke.plist",
                    "offset": [
                        -0.0269,
                        0.708
                    ],
                    "type": "particle"
                },
                {
                    "effect": "boost",
                    "offset": [
                        0.136,
                        0.603
                    ],
                    "type": "particle"
                }
            ],
            "icon": "textures/tuneparts/tunepart_NOS.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "FUEL BOOST"
            },
            "partType": "fuel_boost_superbike",
            "category": "fuel_boost",
            "echoBehavior": "after-stop",
            "rarity": "legendary",
            "triggers": {
                "collect-item": {
                    "oneshot": true,
                    "type": "fuel",
                    "canBeStartedWhileActive": true
                }
            }
        },
        "fuel_magnet": {
            "attachment": {
                "anchor": [
                    0.717,
                    0.123
                ],
                "node": "chassis",
                "scale": 0.01,
                "source": "textures/tuneparts/magnet_fuel.png",
                "type": "sprite"
            },
            "description": "Collect fuel with wider radius.",
            "effects": [
                {
                    "effect": "coin-magnet",
                    "type": "audio"
                },
                {
                    "effect": "coin-magnet",
                    "offset": [
                        0.485,
                        0.71
                    ],
                    "type": "particle"
                }
            ],
            "icon": "textures/tuneparts/magnet_fuel.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "FUEL MAGNET"
            },
            "partType": "fuel_magnet",
            "category": "fuel_magnet",
            "rarity": "common",
            "triggers": {
                "collectible-magnet": {
                    "force": {
                        "from": 20.0,
                        "to": 35.0
                    },
                    "radius": {
                        "from": 5.0,
                        "to": 15.0
                    }
                }
            }
        },
        "fume_boost": {
            "attachment": {
                "node": "chassis",
                "scale": 0.015,
                "source": "textures/tuneparts/fumeboost.png",
                "type": "sprite"
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Power boost when fuel is low."
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "BOOST"
                    },
                    "stat": {
                        "from": 250.0,
                        "to": 450.0
                    },
                    "masteryPowerBoost": true
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": 250.0,
                        "to": 450.0
                    },
                    "type": "acceleration"
                },
                {
                    "effect": "fume-boost",
                    "type": "audio"
                },
                {
                    "effect": "boost",
                    "type": "particle"
                }
            ],
            "icon": "textures/tuneparts/fumeboost.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "FUME BOOST"
            },
            "partType": "fume_boost",
            "category": "fume_boost",
            "echoBehavior": "last-active-duration",
            "rarity": "rare",
            "requireAllTriggersStopToReset": false,
            "triggers": {
                "accelerate": {},
                "air-time": {
                    "direction": -1,
                    "threshold": 0.2
                },
                "fuel": {
                    "direction": -1,
                    "threshold": 20.0
                }
            }
        },
        "glide": {
            "attachment": {
                "anchor": [
                    0.505,
                    0.135
                ],
                "node": "chassis",
                "scale": 0.025,
                "source": "textures/tuneparts/wing.png",
                "type": "sprite",
                "zOrder": 300
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Glide in air."
            },
            "effectDuration": {
                "from": 1.5,
                "to": 2.5
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "BOOST"
                    },
                    "stat": {
                        "from": 100.0,
                        "to": 200.0
                    },
                    "masteryPowerBoost": true
                },
                {
                    "name": {
                        "localize": "Duration of tuning part effect",
                        "value": "DURATION"
                    },
                    "stat": {
                        "from": 1.5,
                        "to": 2.5
                    }
                }
            ],
            "effects": [
                {
                    "type": "air-glide"
                },
                {
                    "amount": {
                        "from": 50.0,
                        "to": 150.0
                    },
                    "type": "acceleration"
                },
                {
                    "effect": "wings",
                    "type": "audio"
                },
                {
                    "effect": "speed",
                    "type": "particle"
                },
                {
                    "curve": {
                        "curve": "sine-out"
                    },
                    "direction": [
                        1.0,
                        -0.4
                    ],
                    "speed": 2.0,
                    "type": "scale"
                }
            ],
            "icon": "textures/tuneparts/wing.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "WINGS"
            },
            "partType": "glide",
            "category": "glide",
            "echoBehavior": "exclusive-after-stop",
            "rarity": "common",
            "triggers": {
                "air-time": {
                    "direction": 1,
                    "threshold": 1.0
                }
            }
        },
        "glide_superbike": {
            "attachment": {
                "anchor": [
                    0.505,
                    0.135
                ],
                "node": "chassis",
                "scale": 0.025,
                "source": "textures/tuneparts/wing.png",
                "type": "sprite",
                "zOrder": 300
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Glide in air."
            },
            "effectDuration": {
                "from": 1.125,
                "to": 1.875
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "BOOST"
                    },
                    "stat": {
                        "from": 100.0,
                        "to": 200.0
                    }
                },
                {
                    "name": {
                        "localize": "Duration of tuning part effect",
                        "value": "DURATION"
                    },
                    "stat": {
                        "from": 1.125,
                        "to": 1.875
                    }
                }
            ],
            "effects": [
                {
                    "type": "air-glide"
                },
                {
                    "amount": {
                        "from": 50.0,
                        "to": 150.0
                    },
                    "type": "acceleration"
                },
                {
                    "effect": "wings",
                    "type": "audio"
                },
                {
                    "effect": "speed",
                    "type": "particle"
                },
                {
                    "curve": {
                        "curve": "sine-out"
                    },
                    "direction": [
                        1.0,
                        -0.4
                    ],
                    "speed": 2.0,
                    "type": "scale"
                }
            ],
            "icon": "textures/tuneparts/wing.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "WINGS"
            },
            "partType": "glide_superbike",
            "category": "glide",
            "echoBehavior": "exclusive-after-stop",
            "rarity": "common",
            "triggers": {
                "air-time": {
                    "direction": 1,
                    "threshold": 1.0
                }
            }
        },
        "glide_hotrod": {
            "attachment": {
                "anchor": [
                    0.505,
                    0.135
                ],
                "node": "chassis",
                "scale": 0.025,
                "source": "textures/tuneparts/wing.png",
                "type": "sprite",
                "zOrder": 300
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Glide in air."
            },
            "effectDuration": {
                "from": 1.125,
                "to": 1.875
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "BOOST"
                    },
                    "stat": {
                        "from": 100.0,
                        "to": 200.0
                    }
                },
                {
                    "name": {
                        "localize": "Duration of tuning part effect",
                        "value": "DURATION"
                    },
                    "stat": {
                        "from": 1.125,
                        "to": 1.875
                    }
                }
            ],
            "effects": [
                {
                    "type": "air-glide"
                },
                {
                    "amount": {
                        "from": 50.0,
                        "to": 150.0
                    },
                    "type": "acceleration"
                },
                {
                    "effect": "wings",
                    "type": "audio"
                },
                {
                    "effect": "speed",
                    "type": "particle"
                },
                {
                    "curve": {
                        "curve": "sine-out"
                    },
                    "direction": [
                        1.0,
                        -0.4
                    ],
                    "speed": 2.0,
                    "type": "scale"
                }
            ],
            "icon": "textures/tuneparts/wing.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "WINGS"
            },
            "partType": "glide_hotrod",
            "category": "glide",
            "echoBehavior": "exclusive-after-stop",
            "rarity": "common",
            "triggers": {
                "air-time": {
                    "direction": 1,
                    "threshold": 1.0
                }
            }
        },
        "glide_electric_car": {
            "attachment": {
                "anchor": [
                    0.505,
                    0.135
                ],
                "node": "chassis",
                "scale": 0.025,
                "source": "textures/tuneparts/wing.png",
                "type": "sprite",
                "zOrder": 300
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Glide in air."
            },
            "effectDuration": {
                "from": 1.125,
                "to": 1.875
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "BOOST"
                    },
                    "stat": {
                        "from": 100.0,
                        "to": 200.0
                    }
                },
                {
                    "name": {
                        "localize": "Duration of tuning part effect",
                        "value": "DURATION"
                    },
                    "stat": {
                        "from": 1.125,
                        "to": 1.875
                    }
                }
            ],
            "effects": [
                {
                    "type": "air-glide"
                },
                {
                    "amount": {
                        "from": 50.0,
                        "to": 150.0
                    },
                    "type": "acceleration"
                },
                {
                    "effect": "wings",
                    "type": "audio"
                },
                {
                    "effect": "speed",
                    "type": "particle"
                },
                {
                    "curve": {
                        "curve": "sine-out"
                    },
                    "direction": [
                        1.0,
                        -0.4
                    ],
                    "speed": 2.0,
                    "type": "scale"
                }
            ],
            "icon": "textures/tuneparts/wing.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "WINGS"
            },
            "partType": "glide_electric_car",
            "category": "glide",
            "echoBehavior": "exclusive-after-stop",
            "rarity": "common",
            "triggers": {
                "air-time": {
                    "direction": 1,
                    "threshold": 1.0
                }
            }
        },
        "glide_lowrider": {
            "attachment": {
                "anchor": [
                    0.505,
                    0.135
                ],
                "node": "chassis",
                "scale": 0.025,
                "source": "textures/tuneparts/wing.png",
                "type": "sprite",
                "zOrder": 300
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Glide in air."
            },
            "effectDuration": {
                "from": 1.125,
                "to": 1.875
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "BOOST"
                    },
                    "stat": {
                        "from": 100.0,
                        "to": 200.0
                    }
                },
                {
                    "name": {
                        "localize": "Duration of tuning part effect",
                        "value": "DURATION"
                    },
                    "stat": {
                        "from": 1.125,
                        "to": 1.875
                    }
                }
            ],
            "effects": [
                {
                    "type": "air-glide"
                },
                {
                    "amount": {
                        "from": 50.0,
                        "to": 150.0
                    },
                    "type": "acceleration"
                },
                {
                    "effect": "wings",
                    "type": "audio"
                },
                {
                    "effect": "speed",
                    "type": "particle"
                },
                {
                    "curve": {
                        "curve": "sine-out"
                    },
                    "direction": [
                        1.0,
                        -0.4
                    ],
                    "speed": 2.0,
                    "type": "scale"
                }
            ],
            "icon": "textures/tuneparts/wing.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "WINGS"
            },
            "partType": "glide_lowrider",
            "category": "glide",
            "echoBehavior": "exclusive-after-stop",
            "rarity": "common",
            "triggers": {
                "air-time": {
                    "direction": 1,
                    "threshold": 1.0
                }
            }
        },
        "glide_musclecar": {
            "attachment": {
                "anchor": [
                    0.505,
                    0.135
                ],
                "node": "chassis",
                "scale": 0.025,
                "source": "textures/tuneparts/wing.png",
                "type": "sprite",
                "zOrder": 300
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Glide in air."
            },
            "effectDuration": {
                "from": 1.5,
                "to": 2.5
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "BOOST"
                    },
                    "stat": {
                        "from": 80.0,
                        "to": 145.0
                    }
                },
                {
                    "name": {
                        "localize": "Duration of tuning part effect",
                        "value": "DURATION"
                    },
                    "stat": {
                        "from": 1.5,
                        "to": 2.5
                    }
                }
            ],
            "effects": [
                {
                    "type": "air-glide"
                },
                {
                    "amount": {
                        "from": 30.0,
                        "to": 95.0
                    },
                    "type": "acceleration"
                },
                {
                    "effect": "wings",
                    "type": "audio"
                },
                {
                    "effect": "speed",
                    "type": "particle"
                },
                {
                    "curve": {
                        "curve": "sine-out"
                    },
                    "direction": [
                        1.0,
                        -0.4
                    ],
                    "speed": 2.0,
                    "type": "scale"
                }
            ],
            "icon": "textures/tuneparts/wing.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "WINGS"
            },
            "partType": "glide_musclecar",
            "category": "glide",
            "echoBehavior": "exclusive-after-stop",
            "rarity": "common",
            "triggers": {
                "air-time": {
                    "direction": 1,
                    "threshold": 1.0
                }
            }
        },
        "heavyweight": {
            "attachment": {
                "node": "chassis",
                "source": "json/parts/weight.json",
                "type": "physicsObject",
                "zOrder": 100
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Increase the amount of damage dealt to breakable objects."
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "WEIGHT"
                    },
                    "stat": {
                        "from": 35.0,
                        "to": 100.0
                    },
                    "masteryPowerBoost": true
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": 81.0,
                        "to": 160.0
                    },
                    "offset": [
                        0.65,
                        0.3
                    ],
                    "type": "acceleration-offset"
                },
                {
                    "amount": {
                        "from": 0.164,
                        "to": 0.2
                    },
                    "direction": [
                        1.0,
                        0.25
                    ],
                    "type": "center-of-mass"
                },
                {
                    "amount": {
                        "from": 0.039,
                        "to": 0.075
                    },
                    "type": "part-mass"
                },
                {
                    "amount": {
                        "from": -0.186,
                        "to": -0.4
                    },
                    "type": "collidable-mass"
                },
                {
                    "amount": {
                        "from": 1.214,
                        "to": 3.0
                    },
                    "type": "damage"
                }
            ],
            "icon": "textures/tuneparts/weight.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "HEAVYWEIGHT"
            },
            "partType": "heavyweight",
            "category": "heavyweight",
            "rarity": "common",
            "triggers": {}
        },
        "heavyweight_scooter": {
            "attachment": {
                "node": "chassis",
                "source": "json/parts/weight.json",
                "type": "physicsObject",
                "zOrder": 100
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Added weight to keep those wheelies under control."
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "WEIGHT"
                    },
                    "stat": {
                        "from": 35.0,
                        "to": 100.0
                    }
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": 171.0,
                        "to": 350.0
                    },
                    "offset": [
                        1.0,
                        0.5
                    ],
                    "type": "acceleration-offset"
                },
                {
                    "amount": {
                        "from": 0.057,
                        "to": 0.2
                    },
                    "type": "center-of-mass"
                },
                {
                    "amount": {
                        "from": 0.064,
                        "to": 0.1
                    },
                    "type": "part-mass"
                },
                {
                    "amount": {
                        "from": -0.186,
                        "to": -0.4
                    },
                    "type": "collidable-mass"
                },
                {
                    "amount": {
                        "from": 1.214,
                        "to": 3.0
                    },
                    "type": "damage"
                }
            ],
            "icon": "textures/tuneparts/weight.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "HEAVYWEIGHT"
            },
            "partType": "heavyweight_scooter",
            "category": "heavyweight",
            "rarity": "common",
            "triggers": {}
        },
        "heavyweight_mass_mod": {
            "attachment": {
                "node": "chassis",
                "source": "json/parts/weight.json",
                "type": "physicsObject",
                "zOrder": 100
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Increase the amount of damage dealt to breakable objects."
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "WEIGHT"
                    },
                    "stat": {
                        "from": 35.0,
                        "to": 100.0
                    }
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": 81.4,
                        "to": 160.0
                    },
                    "offset": [
                        0.65,
                        0.3
                    ],
                    "type": "acceleration-offset"
                },
                {
                    "amount": {
                        "from": 0.077,
                        "to": 0.27
                    },
                    "direction": [
                        1.0,
                        0.0
                    ],
                    "type": "center-of-mass"
                },
                {
                    "amount": {
                        "from": 0.039,
                        "to": 0.075
                    },
                    "type": "part-mass"
                },
                {
                    "amount": {
                        "from": -0.186,
                        "to": -0.4
                    },
                    "type": "collidable-mass"
                },
                {
                    "amount": {
                        "from": 1.214,
                        "to": 3.0
                    },
                    "type": "damage"
                }
            ],
            "icon": "textures/tuneparts/weight.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "HEAVYWEIGHT"
            },
            "partType": "heavyweight_mass_mod",
            "category": "heavyweight",
            "rarity": "common",
            "triggers": {}
        },
        "jump_boost": {
            "attachment": {
                "anchor": [
                    0.5,
                    0.5
                ],
                "node": "chassis",
                "scale": 0.007,
                "source": "textures/tuneparts/jump-shock-tube.png",
                "type": "sprite",
                "zOrder": -1
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Jump up in the air. NOTE: Tap both pedals to activate!"
            },
            "effectDuration": {
                "from": 0.5,
                "to": 0.5
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "BOOST"
                    },
                    "stat": {
                        "from": 500,
                        "to": 1000
                    },
                    "masteryPowerBoost": true
                }
            ],
            "effects": [
                {
                    "effect": "jump-boost",
                    "speedOut": 2.0,
                    "type": "audio"
                },
                {
                    "amount": {
                        "from": 0.45,
                        "to": 0.65
                    },
                    "type": "jump-impulse"
                }
            ],
            "icon": "textures/tuneparts/jump-shock-icon.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "JUMP SHOCKS"
            },
            "partType": "jump_boost",
            "category": "jump_boost",
            "rarity": "rare",
            "triggers": {
                "jump": {}
            }
        },
        "lowrider_jump_boost": {
            "attachment": {
                "anchor": [
                    0.5,
                    0.5
                ],
                "node": "chassis",
                "scale": 0.007,
                "source": "textures/tuneparts/jump-shock-tube.png",
                "type": "sprite",
                "zOrder": -1
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Jump up in the air. NOTE: Tap both pedals to activate!"
            },
            "effectDuration": {
                "from": 0.5,
                "to": 0.5
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "BOOST"
                    },
                    "stat": {
                        "from": 500,
                        "to": 1000
                    }
                }
            ],
            "effects": [
                {
                    "effect": "lowrider-spring",
                    "speedOut": 2.0,
                    "type": "audio"
                },
                {
                    "amount": {
                        "from": 0.45,
                        "to": 0.65
                    },
                    "type": "jump-impulse"
                }
            ],
            "icon": "textures/tuneparts/jump-shock-icon.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "JUMP SHOCKS"
            },
            "partType": "lowrider_jump_boost",
            "category": "jump_boost",
            "rarity": "rare",
            "triggers": {
                "jump": {}
            }
        },
        "magnet": {
            "attachment": {
                "anchor": [
                    0.6,
                    0.107
                ],
                "node": "chassis",
                "scale": 0.01,
                "source": "textures/tuneparts/magnet_coins.png",
                "type": "sprite",
                "zOrder": 255
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Collect fuel and coins with wider radius."
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect. Magnet radius for collecting fuel and coins.",
                        "value": "RADIUS"
                    },
                    "stat": {
                        "from": 5.0,
                        "to": 8.5
                    },
                    "masteryPowerBoost": true
                },
                {
                    "name": {
                        "localize": "Name of tuning part effect. Magnet force for collecting fuel and coins.",
                        "value": "FORCE"
                    },
                    "stat": {
                        "from": 10.0,
                        "to": 30.0
                    }
                }
            ],
            "effects": [
                {
                    "effect": "coin-magnet",
                    "speed": 2.0,
                    "speedOut": 10.0,
                    "type": "audio"
                },
                {
                    "effect": "coin-magnet",
                    "offset": [
                        0.494,
                        0.719
                    ],
                    "type": "particle"
                }
            ],
            "icon": "textures/tuneparts/magnet_coins.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "MAGNET"
            },
            "partType": "magnet",
            "category": "magnet",
            "rarity": "common",
            "triggers": {
                "collectible-magnet": {
                    "force": {
                        "from": 10.0,
                        "to": 30.0
                    },
                    "radius": {
                        "from": 5.0,
                        "to": 8.5
                    },
                    "types": [
                        "coin",
                        "fuel",
                        "gem"
                    ]
                }
            }
        },
        "nitro": {
            "attachment": {
                "anchor": [
                    0.419,
                    0.475
                ],
                "node": "chassis",
                "scale": 0.01,
                "source": "textures/tuneparts/tunepart_nitro.png",
                "type": "sprite"
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Charge on perfect start and excess fuel. Activate with a button."
            },
            "effectDuration": {
                "from": 0.5,
                "to": 0.5
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "IMPULSE"
                    },
                    "stat": {
                        "from": 4.2,
                        "to": 7.0
                    },
                    "masteryPowerBoost": true
                },
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "TOP SPEED"
                    },
                    "stat": {
                        "from": 12.0,
                        "to": 20.0
                    },
                    "masteryPowerBoost": true
                }
            ],
            "effects": [
                {
                    "effect": "nitro",
                    "type": "audio"
                },
                {
                    "amount": {
                        "from": 4.2,
                        "to": 7.0
                    },
                    "direction": [
                        0.75,
                        0.25
                    ],
                    "type": "impulse",
                    "relativeToMass": true
                },
                {
                    "amount": {
                        "from": 12.0,
                        "to": 20.0
                    },
                    "effect": "maxSpeed",
                    "type": "engine-params"
                },
                {
                    "curve": {
                        "curve": " var e := 2.7183; var fxDur := 0.5; var cConst := 1.0; var cXOffset := 0.0; var cMax := 1.0; clamp(((cConst/fxDur)*(x-cXOffset*fxDur))*e^(1.0 - ((cConst/fxDur)*(x-cXOffset*fxDur))), 0, cMax); "
                    },
                    "effect": "particles/particle_tunepart_nitro2.plist",
                    "direction": [
                        0.0,
                        0.0
                    ],
                    "scale": 0.3,
                    "offset": [
                        0.5,
                        0.5
                    ],
                    "flags": [
                        "default",
                        "draw-oldest-first"
                    ],
                    "followPartRotation": false,
                    "type": "particle"
                },
                {
                    "curve": {
                        "curve": " var e := 2.7183; var fxDur := 0.5; var cConst := 12.0; var cXOffset := 0.0; var cMax := 1.0; clamp(((cConst/fxDur)*(x-cXOffset*fxDur))*e^(1.0 - ((cConst/fxDur)*(x-cXOffset*fxDur))), 0, cMax); "
                    },
                    "effect": "particles/particle_tunepart_nitro1.plist",
                    "direction": [
                        0.0,
                        0.0
                    ],
                    "scale": 3.0,
                    "offset": [
                        0.5,
                        0.5
                    ],
                    "flags": [
                        "world-position",
                        "draw-oldest-first"
                    ],
                    "followPartRotation": true,
                    "type": "particle"
                },
                {
                    "curve": {
                        "curve": "sine"
                    },
                    "speed": 2.0,
                    "target": "activationButtonGlow",
                    "type": "opacity",
                    "passive": true,
                    "amount": 1.0
                },
                {
                    "target": "activationButtonIcon",
                    "type": "texture",
                    "originalFilename": "textures/tuneparts/tunepart_nitro_gray.png",
                    "filename": "textures/tuneparts/tunepart_nitro.png",
                    "passive": true,
                    "amount": 0.1
                }
            ],
            "icon": "textures/tuneparts/tunepart_nitro.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "NITRO"
            },
            "partType": "nitro",
            "category": "nitro",
            "echoBehavior": "after-stop",
            "rarity": "legendary",
            "triggers": {
                "button": {
                    "name": "activationButton",
                    "oneshot": true,
                    "requireAllTriggersActiveSameTime": true
                },
                "charge-level": {
                    "threshold": 0.1,
                    "direction": 1.0,
                    "oneshot": true,
                    "types": [
                        "excess-fuel",
                        "perfect-start"
                    ]
                }
            }
        },
        "perfect_landing_boost": {
            "attachment": {
                "node": "chassis",
                "scale": 0.015,
                "source": "textures/tuneparts/landing-boost.png",
                "type": "sprite",
                "zOrder": 300
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Power boost on a perfect landing after a big air."
            },
            "effectDuration": {
                "from": 0.4,
                "to": 0.4
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "IMPULSE"
                    },
                    "stat": {
                        "from": 9.0,
                        "to": 15.0
                    },
                    "masteryPowerBoost": true
                }
            ],
            "effects": [
                {
                    "effect": "spark",
                    "offset": [
                        0.927,
                        0.219
                    ],
                    "type": "particle"
                },
                {
                    "effect": "spark",
                    "offset": [
                        0.0764,
                        0.214
                    ],
                    "type": "particle"
                },
                {
                    "amount": {
                        "from": 9.0,
                        "to": 15.0
                    },
                    "type": "impulse"
                },
                {
                    "effect": "landing-boost",
                    "type": "audio"
                }
            ],
            "icon": "textures/tuneparts/landing-boost.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "LANDING BOOST"
            },
            "partType": "perfect_landing_boost",
            "category": "perfect_landing_boost",
            "echoBehavior": "after-effect",
            "rarity": "epic",
            "triggers": {
                "perfect-landing": {
                    "oneshot": true
                }
            }
        },
        "perfect_start_boost": {
            "attachment": {
                "anchor": [
                    0.663,
                    0.591
                ],
                "node": "chassis",
                "source": "json/parts/rocket.json",
                "type": "physicsObject"
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Active rocket booster on perfect start."
            },
            "detachAfterUse": true,
            "effectDuration": {
                "from": 1.0,
                "to": 1.5
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "BOOST"
                    },
                    "stat": {
                        "from": 700.0,
                        "to": 800.0
                    },
                    "masteryPowerBoost": true
                },
                {
                    "name": {
                        "localize": "Duration of tuning part effect",
                        "value": "DURATION"
                    },
                    "stat": {
                        "from": 0.5,
                        "to": 1.5
                    }
                }
            ],
            "effects": [
                {
                    "effect": "start-boost",
                    "speedOut": 2.0,
                    "type": "audio"
                },
                {
                    "effect": "particles/exhaust_smoke.plist",
                    "offset": [
                        0.00232,
                        0.16
                    ],
                    "type": "particle"
                },
                {
                    "effect": "boost",
                    "offset": [
                        0.205,
                        0.288
                    ],
                    "type": "particle"
                },
                {
                    "amount": {
                        "from": 700.0,
                        "to": 800.0
                    },
                    "type": "acceleration"
                }
            ],
            "icon": "textures/tuneparts/rocket.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "START BOOST"
            },
            "partType": "perfect_start_boost",
            "category": "perfect_start_boost",
            "echoBehavior": "after-stop",
            "rarity": "rare",
            "triggers": {
                "perfect-start": {
                    "disableIfFailed": true,
                    "oneshot": true
                }
            }
        },
        "halved_perfect_start_boost": {
            "attachment": {
                "anchor": [
                    0.663,
                    0.591
                ],
                "node": "chassis",
                "source": "json/parts/rocket.json",
                "type": "physicsObject"
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Active rocket booster on perfect start."
            },
            "detachAfterUse": true,
            "effectDuration": {
                "from": 1.0,
                "to": 1.5
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "BOOST"
                    },
                    "stat": {
                        "from": 300.0,
                        "to": 400.0
                    }
                },
                {
                    "name": {
                        "localize": "Duration of tuning part effect",
                        "value": "DURATION"
                    },
                    "stat": {
                        "from": 0.5,
                        "to": 1.5
                    }
                }
            ],
            "effects": [
                {
                    "effect": "start-boost",
                    "speedOut": 2.0,
                    "type": "audio"
                },
                {
                    "effect": "particles/exhaust_smoke.plist",
                    "offset": [
                        0.00232,
                        0.16
                    ],
                    "type": "particle"
                },
                {
                    "effect": "boost",
                    "offset": [
                        0.205,
                        0.288
                    ],
                    "type": "particle"
                },
                {
                    "amount": {
                        "from": 300.0,
                        "to": 400.0
                    },
                    "type": "acceleration"
                }
            ],
            "icon": "textures/tuneparts/rocket.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "START BOOST"
            },
            "partType": "halved_perfect_start_boost",
            "category": "perfect_start_boost",
            "echoBehavior": "after-stop",
            "rarity": "rare",
            "triggers": {
                "perfect-start": {
                    "disableIfFailed": true,
                    "oneshot": true
                }
            }
        },
        "rollcage": {
            "attachment": {
                "breakable": true,
                "node": "chassis",
                "source": "json/parts/rollcage.json",
                "type": "physicsObject",
                "zOrder": -1
            },
            "attachmentHitPoints": {
                "from": 20.0,
                "to": 55.0
            },
            "attachmentHitSound": "rollcage-hit",
            "description": {
                "localize": "Tuning part description",
                "value": "Protect driver from hits."
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "DURABILITY"
                    },
                    "stat": {
                        "from": 20.0,
                        "to": 55.0
                    },
                    "masteryPowerBoost": true
                }
            ],
            "effects": [
                {
                    "passive": true,
                    "type": "disable-death-from-head-collision"
                }
            ],
            "icon": "textures/tuneparts/roll-cage-icon.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "ROLLCAGE"
            },
            "partType": "rollcage",
            "category": "rollcage",
            "rarity": "common",
            "triggers": {}
        },
        "spoiler": {
            "attachment": {
                "breakable": true,
                "node": "chassis",
                "source": "json/parts/spoiler.json",
                "type": "physicsObject",
                "zOrder": 1
            },
            "attachmentHitPoints": {
                "from": 20.0,
                "to": 20.0
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Increased downforce while in the air. Effect is lost if part gets detached."
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Force of the tuning part effect",
                        "value": "FORCE"
                    },
                    "stat": {
                        "from": 350.0,
                        "to": 1000.0
                    },
                    "masteryPowerBoost": true
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": -7.0,
                        "to": -20.0
                    },
                    "type": "downforce"
                }
            ],
            "icon": "textures/tuneparts/spoiler.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "SPOILER"
            },
            "partType": "spoiler",
            "category": "spoiler",
            "rarity": "epic",
            "triggers": {
                "air-time": {
                    "direction": 1,
                    "threshold": 0.05
                }
            }
        },
        "thrusters": {
            "attachment": {
                "anchor": [
                    0.486,
                    0.486
                ],
                "node": "chassis",
                "scale": 0.007,
                "source": "textures/tuneparts/thruster.png",
                "type": "sprite",
                "zOrder": -1
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Fly through the air (or space). NOTE: Activate by pressing both pedals down!"
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "BOOST"
                    },
                    "stat": {
                        "from": 500,
                        "to": 1000
                    },
                    "masteryPowerBoost": true
                }
            ],
            "effects": [
                {
                    "effect": "thruster",
                    "offset": [
                        0.514,
                        0.2
                    ],
                    "type": "particle"
                },
                {
                    "amount": {
                        "from": 15.16,
                        "to": 22.4
                    },
                    "type": "fuel-consumption"
                },
                {
                    "amount": {
                        "from": 7.58,
                        "to": 11.2
                    },
                    "direction": [
                        0.0,
                        1.0
                    ],
                    "type": "thruster"
                },
                {
                    "effect": "thrusters-boost",
                    "type": "audio"
                }
            ],
            "icon": "textures/tuneparts/thruster_icon.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "THRUSTERS"
            },
            "partType": "thrusters",
            "category": "thrusters",
            "echoBehavior": "last-active-duration",
            "echoDurationCap": 5.0,
            "rarity": "legendary",
            "requireAllTriggersStopToReset": false,
            "triggers": {
                "brake": {},
                "fuel": {
                    "direction": 1,
                    "threshold": 0.0001
                },
                "velocity-x": {
                    "direction": -1,
                    "threshold": 30.0
                },
                "velocity-y": {
                    "direction": -1,
                    "threshold": 30.0
                }
            }
        },
        "turbo_boost": {
            "attachment": {
                "anchor": [
                    0.998,
                    0.313
                ],
                "node": "chassis",
                "scale": 0.015,
                "source": "textures/tuneparts/exhaust_yellow.png",
                "type": "sprite",
                "zOrder": -100
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Charge turbo at maximum pressure for a power boost."
            },
            "effectDuration": {
                "from": 2.5,
                "to": 2.5
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "TOP SPEED"
                    },
                    "stat": {
                        "from": 50.0,
                        "to": 75.0
                    },
                    "masteryPowerBoost": true
                },
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "IMPULSE"
                    },
                    "stat": {
                        "from": 4.0,
                        "to": 10.0
                    },
                    "masteryPowerBoost": true
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": 50.0,
                        "to": 75.0
                    },
                    "curve": {
                        "curve": "1.5*(x^0.25)/(1+4*x^3)",
                        "from": 2.0,
                        "range": [
                            2.0,
                            2.1
                        ],
                        "to": 2.15
                    },
                    "effect": "maxSpeed",
                    "type": "engine-params",
                    "relativeToRotation": false
                },
                {
                    "amount": {
                        "from": 4.0,
                        "to": 10.0
                    },
                    "curve": {
                        "from": 2.0
                    },
                    "type": "impulse",
                    "relativeToRotation": false
                },
                {
                    "curve": {
                        "curve": "exp",
                        "from": 2.0,
                        "to": 2.3
                    },
                    "effect": "turbo-boost",
                    "restart": true,
                    "speedOut": 2.0,
                    "type": "audio"
                },
                {
                    "curve": {
                        "from": 2.0,
                        "to": 3.0
                    },
                    "effect": "boost",
                    "offset": [
                        0.0862,
                        0.6
                    ],
                    "type": "particle"
                },
                {
                    "amount": 100.0,
                    "curve": {
                        "curve": "exp",
                        "from": 0.5,
                        "to": 2.0
                    },
                    "speed": 3.0,
                    "target": "boostHand",
                    "type": "shake"
                },
                {
                    "amount": 2.0,
                    "curve": {
                        "curve": "exp",
                        "from": 0.5,
                        "to": 2.0
                    },
                    "speed": 50.0,
                    "target": "boost",
                    "type": "shake"
                }
            ],
            "icon": "textures/tuneparts/exhaust_yellow.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "OVERCHARGED TURBO"
            },
            "partType": "turbo_boost",
            "category": "turbo_boost",
            "echoBehavior": "after-effect",
            "rarity": "epic",
            "triggers": {
                "turbo": {
                    "direction": 1,
                    "threshold": 0.9
                }
            }
        },
        "turbo_boost_nerf": {
            "attachment": {
                "anchor": [
                    0.998,
                    0.313
                ],
                "node": "chassis",
                "scale": 0.015,
                "source": "textures/tuneparts/exhaust_yellow.png",
                "type": "sprite",
                "zOrder": -100
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Charge turbo at maximum pressure for a power boost."
            },
            "effectDuration": {
                "from": 2.5,
                "to": 2.5
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "TOP SPEED"
                    },
                    "stat": {
                        "from": 45.0,
                        "to": 70.0
                    }
                },
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "IMPULSE"
                    },
                    "stat": {
                        "from": 4.0,
                        "to": 10.0
                    }
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": 45.0,
                        "to": 70.0
                    },
                    "curve": {
                        "curve": "1.5*(x^0.25)/(1+4*x^3)",
                        "from": 2.0,
                        "range": [
                            2.0,
                            2.1
                        ],
                        "to": 2.15
                    },
                    "effect": "maxSpeed",
                    "type": "engine-params",
                    "relativeToRotation": false
                },
                {
                    "amount": {
                        "from": 4.0,
                        "to": 10.0
                    },
                    "curve": {
                        "from": 2.0
                    },
                    "type": "impulse",
                    "relativeToRotation": false
                },
                {
                    "curve": {
                        "curve": "exp",
                        "from": 2.0,
                        "to": 2.3
                    },
                    "effect": "turbo-boost",
                    "restart": true,
                    "speedOut": 2.0,
                    "type": "audio"
                },
                {
                    "curve": {
                        "from": 2.0,
                        "to": 3.0
                    },
                    "effect": "boost",
                    "offset": [
                        0.0862,
                        0.6
                    ],
                    "type": "particle"
                },
                {
                    "amount": 100.0,
                    "curve": {
                        "curve": "exp",
                        "from": 0.5,
                        "to": 2.0
                    },
                    "speed": 3.0,
                    "target": "boostHand",
                    "type": "shake"
                },
                {
                    "amount": 2.0,
                    "curve": {
                        "curve": "exp",
                        "from": 0.5,
                        "to": 2.0
                    },
                    "speed": 50.0,
                    "target": "boost",
                    "type": "shake"
                }
            ],
            "icon": "textures/tuneparts/exhaust_yellow.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "OVERCHARGED TURBO"
            },
            "partType": "turbo_boost_nerf",
            "category": "turbo_boost",
            "echoBehavior": "after-effect",
            "rarity": "epic",
            "triggers": {
                "turbo": {
                    "direction": 1,
                    "threshold": 0.9
                }
            }
        },
        "wheelie_boost": {
            "attachment": {
                "anchor": [
                    0.701,
                    0.797
                ],
                "node": "chassis",
                "scale": 0.015,
                "source": "textures/tuneparts/topspeed.png",
                "type": "sprite"
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Power boost on wheelies."
            },
            "effectDuration": {
                "from": 5.0,
                "to": 5.0
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "BOOST"
                    },
                    "stat": {
                        "from": 300.0,
                        "to": 400.0
                    },
                    "masteryPowerBoost": true
                },
                {
                    "name": {
                        "localize": "Duration of tuning part effect",
                        "value": "DURATION"
                    },
                    "stat": {
                        "from": 0.5,
                        "to": 1.0
                    }
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": 83.0,
                        "to": 350.0
                    },
                    "direction": [
                        0.9,
                        -0.4
                    ],
                    "offset": [
                        -1.0,
                        -0.6
                    ],
                    "type": "acceleration"
                },
                {
                    "effect": "wheelie-boost",
                    "restart": true,
                    "speedOut": 2.0,
                    "type": "audio"
                },
                {
                    "effect": "boost",
                    "offset": [
                        0.419,
                        0.271
                    ],
                    "type": "particle"
                }
            ],
            "icon": "textures/tuneparts/topspeed.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "WHEELIE BOOST"
            },
            "partType": "wheelie_boost",
            "category": "wheelie_boost",
            "echoBehavior": "last-active-duration",
            "echoDurationCap": 5.0,
            "rarity": "rare",
            "triggers": {
                "wheelie-time": {
                    "direction": 1,
                    "hold": {
                        "from": 0.5,
                        "to": 1.0
                    },
                    "threshold": 1.0
                }
            }
        },
        "winter_tyres": {
            "attachment": {
                "scale": 0.0075,
                "source": "textures/tuneparts/snow-chain.png",
                "type": "sprite",
                "zOrder": 255
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Increased overall grip with special bonus on snow and icy surfaces."
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "GRIP ON SNOW"
                    },
                    "stat": {
                        "from": 150.0,
                        "to": 500.0
                    },
                    "masteryPowerBoost": true
                },
                {
                    "name": {
                        "localize": "Duration of tuning part effect",
                        "value": "GRIP"
                    },
                    "stat": {
                        "from": 50.0,
                        "to": 150.0
                    },
                    "masteryPowerBoost": true
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": 1.5,
                        "to": 5.0
                    },
                    "type": "wheel-friction"
                },
                {
                    "amount": {
                        "from": 0.5,
                        "to": 1.5
                    },
                    "passive": true,
                    "type": "wheel-friction"
                }
            ],
            "icon": "textures/tuneparts/snow-chain-icon.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "WINTER TIRES"
            },
            "partType": "winter_tyres",
            "category": "winter_tyres",
            "rarity": "common",
            "triggers": {
                "surface-in-contact": {
                    "type": [
                        "snow"
                    ]
                }
            }
        },
        "winter_tyres_racing_truck": {
            "attachment": {
                "scale": 0.0075,
                "source": "textures/tuneparts/snow-chain.png",
                "type": "sprite",
                "zOrder": 255
            },
            "description": {
                "localize": "Tuning part description",
                "value": "Increased overall grip with special bonus on snow and icy surfaces."
            },
            "effectStats": [
                {
                    "name": {
                        "localize": "Name of tuning part effect",
                        "value": "GRIP ON SNOW"
                    },
                    "stat": {
                        "from": 50.0,
                        "to": 400.0
                    }
                },
                {
                    "name": {
                        "localize": "Duration of tuning part effect",
                        "value": "GRIP"
                    },
                    "stat": {
                        "from": 15.0,
                        "to": 100.0
                    }
                }
            ],
            "effects": [
                {
                    "amount": {
                        "from": 0.5,
                        "to": 4.0
                    },
                    "type": "wheel-friction"
                },
                {
                    "amount": {
                        "from": 0.15,
                        "to": 1.0
                    },
                    "passive": true,
                    "type": "wheel-friction"
                }
            ],
            "icon": "textures/tuneparts/snow-chain-icon.png",
            "name": {
                "localize": "Name of tuning part, keep it short",
                "value": "WINTER TIRES"
            },
            "partType": "winter_tyres_racing_truck",
            "category": "winter_tyres",
            "rarity": "common",
            "triggers": {
                "surface-in-contact": {
                    "type": [
                        "snow"
                    ]
                }
            }
        }
    }
}
]]