// lib/utils/constants.dart
import 'package:flutter/material.dart';

// ── VoltShift palette: green phosphor CRT terminal ──────────────────────
const Color kBg          = Color(0xFF030A05);
const Color kSurface     = Color(0xFF07140B);
const Color kBorder      = Color(0xFF14431F);
const Color kAccent      = Color(0xFF39FF6E); // phosphor green
const Color kTraceOff    = Color(0xFF1B5E2C);
const Color kTraceOn     = Color(0xFF39FF6E);
const Color kSourceColor = Color(0xFFB9FF59); // charged lime
const Color kBulbOff     = Color(0xFF2F3D2F);
const Color kBulbOn      = Color(0xFFEFFF8A); // bright phosphor lamp
const Color kTextPrimary = Color(0xFFD8FFE0);
const Color kTextDim     = Color(0xFF5E9E6E);

const Color kStarOn  = Color(0xFFEFFF8A);
const Color kStarOff = Color(0xFF14351C);

const Color kEasyColor   = Color(0xFF39FF6E);
const Color kMediumColor = Color(0xFFB9FF59);
const Color kHardColor   = Color(0xFFFFAB40);

const int kTotalLevels = 150;

TextStyle techno(double size,
        {Color color = kTextPrimary,
        FontWeight weight = FontWeight.bold,
        double letterSpacing = 1.5}) =>
    TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing);
