#!/bin/bash

# Script para crear estructura de directorios de RolinChat
# Ejecutar desde la raíz del proyecto Godot

echo "Creando estructura de directorios para RolinChat..."

# Crear directorios principales
mkdir -p assets/sprites/avatars/isometric/{bodies,hair,outfits}
mkdir -p assets/sprites/avatars/sideview/{heads,torsos,legs,hair,outfits_top,outfits_bottom,shoes}
mkdir -p assets/sprites/maps/{tiles,objects}
mkdir -p assets/sprites/ui/{buttons,panels,icons}
mkdir -p assets/audio/{music,sfx}
mkdir -p assets/fonts

mkdir -p data/avatar_registries
mkdir -p data/scene_templates
mkdir -p data/maps
mkdir -p data/default_profiles

mkdir -p scenes/main_menu
mkdir -p scenes/avatar_creator
mkdir -p scenes/game_world
mkdir -p scenes/joint_animations
mkdir -p scenes/ui

mkdir -p scripts/autoloads
mkdir -p scripts/systems/avatar
mkdir -p scripts/systems/networking
mkdir -p scripts/systems/chat
mkdir -p scripts/systems/scene_system
mkdir -p scripts/systems/world
mkdir -p scripts/ui

mkdir -p addons

echo "✓ Estructura de directorios creada exitosamente"

# Crear archivos .gdignore para carpetas que no necesitan ser importadas
touch assets/sprites/avatars/isometric/.gdignore
touch assets/sprites/avatars/sideview/.gdignore

echo "✓ Archivos .gdignore creados"

echo ""
echo "Estructura del proyecto RolinChat lista."
echo "Siguiente paso: Crear autoloads básicos"
