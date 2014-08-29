--- Copyright (c) 2014 Jeremy Avigad. All rights reserved.
--- Released under Apache 2.0 license as described in the file LICENSE.
--- Author: Jeremy Avigad

-- div.lean
-- ========
--
-- This is a continuation of the development of the natural numbers, with a general way of
-- defining recursive functions, and definitions of div, mod, and gcd.

import logic .sub struc.relation data.prod
import tools.fake_simplifier

using nat relation relation.iff_ops prod
using fake_simplifier decidable
using eq_ops

namespace nat

-- A general recursion principle
-- -----------------------------
--
-- Data:
--
--   dom, codom : Type
--   default : codom
--   measure : dom → ℕ
--   rec_val : dom → (dom → codom) → codom
--
-- and a proof
--
--   rec_decreasing : ∀m, m ≥ measure x, rec_val x f = rec_val x (restrict f m)
--
-- ... which says that the recursive call only depends on f at values with measure less than x,
-- in the sense that changing other values to the default value doesn't change the result.
--
-- The result is a function f = rec_measure, satisfying
--
--   f x = rec_val x f

definition restrict {dom codom : Type} (default : codom) (measure : dom → ℕ) (f : dom → codom)
    (m : ℕ) (x : dom) :=
if measure x < m then f x else default

theorem restrict_lt_eq {dom codom : Type} (default : codom) (measure : dom → ℕ) (f : dom → codom)
    (m : ℕ) (x : dom) (H : measure x < m) :
  restrict default measure f m x = f x :=
if_pos H

theorem restrict_not_lt_eq {dom codom : Type} (default : codom) (measure : dom → ℕ)
    (f : dom → codom) (m : ℕ) (x : dom) (H : ¬ measure x < m) :
  restrict default measure f m x = default :=
if_neg H

definition rec_measure_aux {dom codom : Type} (default : codom) (measure : dom → ℕ)
    (rec_val : dom → (dom → codom) → codom) : ℕ → dom → codom :=
nat_rec (λx, default) (λm g x, if measure x < succ m then rec_val x g else default)

definition rec_measure {dom codom : Type} (default : codom) (measure : dom → ℕ)
    (rec_val : dom → (dom → codom) → codom) (x : dom) : codom :=
rec_measure_aux default measure rec_val (succ (measure x)) x

theorem rec_measure_aux_spec {dom codom : Type} (default : codom) (measure : dom → ℕ)
    (rec_val : dom → (dom → codom) → codom)
    (rec_decreasing : ∀g1 g2 x, (∀z, measure z < measure x → g1 z = g2 z) →
        rec_val x g1 = rec_val x g2)
    (m : ℕ) :
  let f' := rec_measure_aux default measure rec_val in
  let f := rec_measure default measure rec_val in
  ∀x, f' m x = restrict default measure f m x :=
let f' := rec_measure_aux default measure rec_val in
let f  := rec_measure default measure rec_val in
case_strong_induction_on m
  (take x,
    have H1 : f' 0 x = default, from rfl,
    have H2 [fact]: ¬ measure x < 0, from not_lt_zero,
    have H3 : restrict default measure f 0 x = default, from if_neg H2,
    show f' 0 x = restrict default measure f 0 x, from trans H1 (symm H3))
  (take m,
    assume IH: ∀n, n ≤ m → ∀x, f' n x = restrict default measure f n x,
    take x : dom,
    show f' (succ m) x = restrict default measure f (succ m) x, from
      by_cases -- (measure x < succ m)
        (assume H1 : measure x < succ m,
          have H2a : ∀z, measure z < measure x → f' m z = f z, from
            take z,
              assume Hzx : measure z < measure x,
              calc
                f' m z = restrict default measure f m z : IH m le_refl z
                  ... = f z : restrict_lt_eq _ _ _ _ _ (lt_le_trans Hzx (lt_succ_imp_le H1)),
          have H2 [fact] : f' (succ m) x = rec_val x f, from
            calc
              f' (succ m) x = if measure x < succ m then rec_val x (f' m) else default : rfl
                ... = rec_val x (f' m) : if_pos H1
                ... = rec_val x f : rec_decreasing (f' m) f x H2a,
          let m' := measure x in
          have H3a : ∀z, measure z < m' → f' m' z = f z, from
            take z,
              assume Hzx : measure z < measure x,
              calc
                f' m' z = restrict default measure f m' z : IH _ (lt_succ_imp_le H1) _
                  ... = f z : restrict_lt_eq _ _ _ _ _ Hzx,
          have H3 : restrict default measure f (succ m) x = rec_val x f, from
            calc
              restrict default measure f (succ m) x = f x : if_pos H1
                ... = f' (succ m') x : refl _
                ... = if measure x < succ m' then rec_val x (f' m') else default : rfl
                ... = rec_val x (f' m') : if_pos self_lt_succ
                ... = rec_val x f : rec_decreasing _ _ _ H3a,
          show f' (succ m) x = restrict default measure f (succ m) x,
            from trans H2 (symm H3))
        (assume H1 : ¬ measure x < succ m,
          have H2 : f' (succ m) x = default, from
            calc
              f' (succ m) x = if measure x < succ m then rec_val x (f' m) else default : rfl
                ... = default : if_neg H1,
          have H3 : restrict default measure f (succ m) x = default,
            from if_neg H1,
          show f' (succ m) x = restrict default measure f (succ m) x,
            from trans H2 (symm H3)))

theorem rec_measure_spec {dom codom : Type} {default : codom} {measure : dom → ℕ}
    (rec_val : dom → (dom → codom) → codom)
    (rec_decreasing : ∀g1 g2 x, (∀z, measure z < measure x → g1 z = g2 z) →
        rec_val x g1 = rec_val x g2)
    (x : dom):
  let f := rec_measure default measure rec_val in
  f x = rec_val x f :=
let f' := rec_measure_aux default measure rec_val in
let f  := rec_measure default measure rec_val in
let m  := measure x in
have H : ∀z, measure z < measure x → f' m z = f z, from
  take z,
    assume H1 : measure z < measure x,
    calc
      f' m z = restrict default measure f m z : rec_measure_aux_spec _ _ _ rec_decreasing m z
        ... = f z : restrict_lt_eq _ _ _ _ _ H1,
calc
  f x = f' (succ m) x : rfl
    ... = if measure x < succ m then rec_val x (f' m) else default : rfl
    ... = rec_val x (f' m) : if_pos (self_lt_succ)
    ... = rec_val x f : rec_decreasing _ _ _ H


-- Div and mod
-- -----------

-- ### the definition of div

-- for fixed y, recursive call for x div y
definition div_aux_rec (y : ℕ) (x : ℕ) (div_aux' : ℕ → ℕ) : ℕ :=
if (y = 0 ∨ x < y) then 0 else succ (div_aux' (x - y))

definition div_aux (y : ℕ) : ℕ → ℕ := rec_measure 0 (fun x, x) (div_aux_rec y)

theorem div_aux_decreasing (y : ℕ) (g1 g2 : ℕ → ℕ) (x : ℕ) (H : ∀z, z < x → g1 z = g2 z) :
  div_aux_rec y x g1 = div_aux_rec y x g2 :=
let lhs := div_aux_rec y x g1 in
let rhs := div_aux_rec y x g2 in
show lhs = rhs, from
  by_cases -- (y = 0 ∨ x < y)
    (assume H1 : y = 0 ∨ x < y,
      calc
        lhs = 0     : if_pos H1
          ... = rhs : (if_pos H1)⁻¹)
    (assume H1 : ¬ (y = 0 ∨ x < y),
      have H2a : y ≠ 0, from assume H, H1 (or_intro_left _ H),
     have H2b : ¬ x < y, from assume H, H1 (or_intro_right _ H),
      have ypos : y > 0, from ne_zero_imp_pos H2a,
      have xgey : x ≥ y, from not_lt_imp_ge H2b,
      have H4 : x - y < x, from sub_lt (lt_le_trans ypos xgey) ypos,
      calc
        lhs = succ (g1 (x - y)) : if_neg H1
          ... = succ (g2 (x - y)) : {H _ H4}
          ... = rhs : symm (if_neg H1))

theorem div_aux_spec (y : ℕ) (x : ℕ) :
  div_aux y x = if (y = 0 ∨ x < y) then 0 else succ (div_aux y (x - y)) :=
rec_measure_spec (div_aux_rec y) (div_aux_decreasing y) x

definition idivide (x : ℕ) (y : ℕ) : ℕ := div_aux y x

infixl `div` := idivide

theorem div_zero {x : ℕ} : x div 0 = 0 :=
trans (div_aux_spec _ _) (if_pos (or_inl rfl))

-- add_rewrite div_zero

theorem div_less {x y : ℕ} (H : x < y) : x div y = 0 :=
trans (div_aux_spec _ _) (if_pos (or_inr H))

-- add_rewrite div_less

theorem zero_div {y : ℕ} : 0 div y = 0 :=
case y div_zero (take y', div_less succ_pos)

-- add_rewrite zero_div

theorem div_rec {x y : ℕ} (H1 : y > 0) (H2 : x ≥ y) : x div y = succ ((x - y) div y) :=
have H3 : ¬ (y = 0 ∨ x < y), from
  not_intro
    (assume H4 : y = 0 ∨ x < y,
      or_elim H4
        (assume H5 : y = 0, not_elim lt_irrefl (subst H5 H1))
        (assume H5 : x < y, not_elim (lt_imp_not_ge H5) H2)),
trans (div_aux_spec _ _) (if_neg H3)

theorem div_add_self_right {x z : ℕ} (H : z > 0) : (x + z) div z = succ (x div z) :=
have H1 : z ≤ x + z, by simp,
let H2 := div_rec H H1 in
by simp

theorem div_add_mul_self_right {x y z : ℕ} (H : z > 0) : (x + y * z) div z = x div z + y :=
induction_on y (by simp)
  (take y,
    assume IH : (x + y * z) div z = x div z + y,
    calc
      (x + succ y * z) div z = (x + y * z + z) div z    : by simp
                         ... = succ ((x + y * z) div z) : div_add_self_right H
                         ... = x div z + succ y         : by simp)


-- ### The definition of mod

-- for fixed y, recursive call for x mod y
definition mod_aux_rec (y : ℕ) (x : ℕ) (mod_aux' : ℕ → ℕ) : ℕ :=
if (y = 0 ∨ x < y) then x else mod_aux' (x - y)

definition mod_aux (y : ℕ) : ℕ → ℕ := rec_measure 0 (fun x, x) (mod_aux_rec y)

theorem mod_aux_decreasing (y : ℕ) (g1 g2 : ℕ → ℕ) (x : ℕ) (H : ∀z, z < x → g1 z = g2 z) :
  mod_aux_rec y x g1 = mod_aux_rec y x g2 :=
let lhs := mod_aux_rec y x g1 in
let rhs := mod_aux_rec y x g2 in
show lhs = rhs, from
  by_cases -- (y = 0 ∨ x < y)
    (assume H1 : y = 0 ∨ x < y,
      calc
        lhs = x : if_pos H1
          ... = rhs : (if_pos H1)⁻¹)
    (assume H1 : ¬ (y = 0 ∨ x < y),
      have H2a : y ≠ 0, from assume H, H1 (or_intro_left _ H),
      have H2b : ¬ x < y, from assume H, H1 (or_intro_right _ H),
      have ypos : y > 0, from ne_zero_imp_pos H2a,
      have xgey : x ≥ y, from not_lt_imp_ge H2b,
      have H4 : x - y < x, from sub_lt (lt_le_trans ypos xgey) ypos,
      calc
        lhs = g1 (x - y) : if_neg H1
          ... = g2 (x - y) : H _ H4
          ... = rhs : symm (if_neg H1))

theorem mod_aux_spec (y : ℕ) (x : ℕ) :
  mod_aux y x = if (y = 0 ∨ x < y) then x else mod_aux y (x - y) :=
rec_measure_spec (mod_aux_rec y) (mod_aux_decreasing y) x

definition modulo (x : ℕ) (y : ℕ) : ℕ := mod_aux y x

infixl `mod` := modulo

theorem mod_zero {x : ℕ} : x mod 0 = x :=
trans (mod_aux_spec _ _) (if_pos (or_inl rfl))

-- add_rewrite mod_zero

theorem mod_lt_eq {x y : ℕ} (H : x < y) : x mod y = x :=
trans (mod_aux_spec _ _) (if_pos (or_inr H))

-- add_rewrite mod_lt_eq

theorem zero_mod {y : ℕ} : 0 mod y = 0 :=
case y mod_zero (take y', mod_lt_eq succ_pos)

-- add_rewrite zero_mod

theorem mod_rec {x y : ℕ} (H1 : y > 0) (H2 : x ≥ y) : x mod y = (x - y) mod y :=
have H3 : ¬ (y = 0 ∨ x < y), from
  not_intro
    (assume H4 : y = 0 ∨ x < y,
      or_elim H4
        (assume H5 : y = 0, not_elim lt_irrefl (H5 ▸ H1))
        (assume H5 : x < y, not_elim (lt_imp_not_ge H5) H2)),
(mod_aux_spec _ _) ⬝ (if_neg H3)

-- need more of these, add as rewrite rules
theorem mod_add_self_right {x z : ℕ} (H : z > 0) : (x + z) mod z = x mod z :=
have H1 : z ≤ x + z, by simp,
let H2 := mod_rec H H1 in
by simp

theorem mod_add_mul_self_right {x y z : ℕ} (H : z > 0) : (x + y * z) mod z = x mod z :=
induction_on y (by simp)
  (take y,
    assume IH : (x + y * z) mod z = x mod z,
    calc
      (x + succ y * z) mod z = (x + y * z + z) mod z : by simp
                         ... = (x + y * z) mod z     : mod_add_self_right H
                         ... = x mod z               : IH)

theorem mod_mul_self_right {m n : ℕ} : (m * n) mod n = 0 :=
case_zero_pos n (by simp)
  (take n,
    assume npos : n > 0,
    (by simp) ▸ (@mod_add_mul_self_right 0 m _ npos))

-- add_rewrite mod_mul_self_right

theorem mod_mul_self_left {m n : ℕ} : (m * n) mod m = 0 :=
mul_comm ▸ mod_mul_self_right

-- add_rewrite mod_mul_self_left

-- ### properties of div and mod together

theorem mod_lt {x y : ℕ} (H : y > 0) : x mod y < y :=
case_strong_induction_on x
  (show 0 mod y < y, from zero_mod⁻¹ ▸ H)
  (take x,
    assume IH : ∀x', x' ≤ x → x' mod y < y,
    show succ x mod y < y, from
      by_cases -- (succ x < y)
        (assume H1 : succ x < y,
          have H2 : succ x mod y = succ x, from mod_lt_eq H1,
          show succ x mod y < y, from H2⁻¹ ▸ H1)
        (assume H1 : ¬ succ x < y,
          have H2 : y ≤ succ x, from not_lt_imp_ge H1,
          have H3 : succ x mod y = (succ x - y) mod y, from mod_rec H H2,
          have H4 : succ x - y < succ x, from sub_lt succ_pos H,
          have H5 : succ x - y ≤ x, from lt_succ_imp_le H4,
          show succ x mod y < y, from subst (symm H3) (IH _ H5)))

theorem div_mod_eq {x y : ℕ} : x = x div y * y + x mod y :=
case_zero_pos y
  (show x = x div 0 * 0 + x mod 0, from
    symm (calc
      x div 0 * 0 + x mod 0 = 0 + x mod 0 : {mul_zero_right}
        ... = x mod 0 : add_zero_left
        ... = x : mod_zero))
  (take y,
    assume H : y > 0,
    show x = x div y * y + x mod y, from
      case_strong_induction_on x
        (show 0 = (0 div y) * y + 0 mod y, by simp)
        (take x,
          assume IH : ∀x', x' ≤ x → x' = x' div y * y + x' mod y,
          show succ x = succ x div y * y + succ x mod y, from
            by_cases -- (succ x < y)
              (assume H1 : succ x < y,
                have H2 : succ x div y = 0, from div_less H1,
                have H3 : succ x mod y = succ x, from mod_lt_eq H1,
                by simp)
              (assume H1 : ¬ succ x < y,
                have H2 : y ≤ succ x, from not_lt_imp_ge H1,
                have H3 : succ x div y = succ ((succ x - y) div y), from div_rec H H2,
                have H4 : succ x mod y = (succ x - y) mod y, from mod_rec H H2,
                have H5 : succ x - y < succ x, from sub_lt succ_pos H,
                have H6 : succ x - y ≤ x, from lt_succ_imp_le H5,
                symm (calc
                  succ x div y * y + succ x mod y = succ ((succ x - y) div y) * y + succ x mod y :
                      {H3}
                    ... = ((succ x - y) div y) * y + y + succ x mod y : {mul_succ_left}
                    ... = ((succ x - y) div y) * y + y + (succ x - y) mod y : {H4}
                    ... = ((succ x - y) div y) * y + (succ x - y) mod y + y : add_right_comm
                    ... = succ x - y + y : {(IH _ H6)⁻¹}
                    ... = succ x : add_sub_ge_left H2))))

theorem mod_le {x y : ℕ} : x mod y ≤ x :=
div_mod_eq⁻¹ ▸ le_add_left

--- a good example where simplifying using the context causes problems
theorem remainder_unique {y : ℕ} (H : y > 0) {q1 r1 q2 r2 : ℕ} (H1 : r1 < y) (H2 : r2 < y)
  (H3 : q1 * y + r1 = q2 * y + r2) : r1 = r2 :=
calc
  r1 = r1 mod y : by simp
    ... = (r1 + q1 * y) mod y : (mod_add_mul_self_right H)⁻¹
    ... = (q1 * y + r1) mod y : {add_comm}
    ... = (r2 + q2 * y) mod y : by simp
    ... = r2 mod y            : mod_add_mul_self_right H
    ... = r2                  : by simp

theorem quotient_unique {y : ℕ} (H : y > 0) {q1 r1 q2 r2 : ℕ} (H1 : r1 < y) (H2 : r2 < y)
  (H3 : q1 * y + r1 = q2 * y + r2) : q1 = q2 :=
have H4 : q1 * y + r2 = q2 * y + r2, from subst (remainder_unique H H1 H2 H3) H3,
have H5 : q1 * y = q2 * y, from add_cancel_right H4,
have H6 : y > 0, from le_lt_trans zero_le H1,
show q1 = q2, from mul_cancel_right H6 H5

theorem div_mul_mul {z x y : ℕ} (zpos : z > 0) : (z * x) div (z * y) = x div y :=
by_cases -- (y = 0)
  (assume H : y = 0, by simp)
  (assume H : y ≠ 0,
    have ypos : y > 0, from ne_zero_imp_pos H,
    have zypos : z * y > 0, from mul_pos zpos ypos,
    have H1 : (z * x) mod (z * y) < z * y, from mod_lt zypos,
    have H2 : z * (x mod y) < z * y, from mul_lt_left zpos (mod_lt ypos),
    quotient_unique zypos H1 H2
      (calc
        ((z * x) div (z * y)) * (z * y) + (z * x) mod (z * y) = z * x : div_mod_eq⁻¹
          ... = z * (x div y * y + x mod y)                           : {div_mod_eq}
          ... = z * (x div y * y) + z * (x mod y)                     : mul_distr_left
          ... = (x div y) * (z * y) + z * (x mod y)                   : {mul_left_comm}))
--- something wrong with the term order
---            ... = (x div y) * (z * y) + z * (x mod y) : by simp))

theorem mod_mul_mul {z x y : ℕ} (zpos : z > 0) : (z * x) mod (z * y) = z * (x mod y) :=
by_cases -- (y = 0)
  (assume H : y = 0, by simp)
  (assume H : y ≠ 0,
    have ypos : y > 0, from ne_zero_imp_pos H,
    have zypos : z * y > 0, from mul_pos zpos ypos,
    have H1 : (z * x) mod (z * y) < z * y, from mod_lt zypos,
    have H2 : z * (x mod y) < z * y, from mul_lt_left zpos (mod_lt ypos),
    remainder_unique zypos H1 H2
      (calc
        ((z * x) div (z * y)) * (z * y) + (z * x) mod (z * y) = z * x : div_mod_eq⁻¹
          ... = z * (x div y * y + x mod y) : {div_mod_eq}
          ... = z * (x div y * y) + z * (x mod y) : mul_distr_left
          ... = (x div y) * (z * y) + z * (x mod y) : {mul_left_comm}))

theorem mod_one {x : ℕ} : x mod 1 = 0 :=
have H1 : x mod 1 < 1, from mod_lt succ_pos,
le_zero (lt_succ_imp_le H1)

-- add_rewrite mod_one

theorem mod_self {n : ℕ} : n mod n = 0 :=
case n (by simp)
  (take n,
    have H : (succ n * 1) mod (succ n * 1) = succ n * (1 mod 1),
      from mod_mul_mul succ_pos,
    (by simp) ▸ H)

-- add_rewrite mod_self

theorem div_one {n : ℕ} : n div 1 = n :=
have H : n div 1 * 1 + n mod 1 = n, from div_mod_eq⁻¹,
(by simp) ▸ H

-- add_rewrite div_one

theorem pos_div_self {n : ℕ} (H : n > 0) : n div n = 1 :=
have H1 : (n * 1) div (n * 1) = 1 div 1, from div_mul_mul H,
(by simp) ▸ H1

-- add_rewrite pos_div_self

-- Divides
-- -------

definition dvd (x y : ℕ) : Prop := y mod x = 0

infix `|` := dvd

theorem dvd_iff_mod_eq_zero {x y : ℕ} : x | y ↔ y mod x = 0 :=
refl _

theorem dvd_imp_div_mul_eq {x y : ℕ} (H : y | x) : x div y * y = x :=
symm (calc
  x = x div y * y + x mod y : div_mod_eq
    ... = x div y * y + 0 : {mp dvd_iff_mod_eq_zero H}
    ... = x div y * y : add_zero_right)

-- add_rewrite dvd_imp_div_mul_eq

theorem mul_eq_imp_dvd {z x y : ℕ} (H : z * y = x) :  y | x :=
have H1 : z * y = x mod y + x div y * y, from
  H ⬝ div_mod_eq ⬝ add_comm,
have H2 : (z - x div y) * y = x mod y, from
  calc
    (z - x div y) * y = z * y - x div y * y      : mul_sub_distr_right
       ... = x mod y + x div y * y - x div y * y : {H1}
       ... = x mod y                             : sub_add_left,
show x mod y = 0, from
  by_cases
    (assume yz : y = 0,
      have xz : x = 0, from
        calc
          x = z * y     : H⁻¹
            ... = z * 0 : {yz}
            ... = 0     : mul_zero_right,
      calc
        x mod y = x mod 0 : {yz}
          ... = x         : mod_zero
          ... = 0         : xz)
    (assume ynz : y ≠ 0,
      have ypos : y > 0, from ne_zero_imp_pos ynz,
      have H3 : (z - x div y) * y < y, from H2⁻¹ ▸ mod_lt ypos,
      have H4 : (z - x div y) * y < 1 * y, from mul_one_left⁻¹ ▸ H3,
      have H5 : z - x div y < 1, from mul_lt_cancel_right H4,
      have H6 : z - x div y = 0, from le_zero (lt_succ_imp_le H5),
      calc
        x mod y = (z - x div y) * y : H2⁻¹
            ... = 0 * y : {H6}
            ... = 0 : mul_zero_left)

theorem dvd_iff_exists_mul {x y : ℕ} : x | y ↔ ∃z, z * x = y :=
iff_intro
  (assume H : x | y,
    show ∃z, z * x = y, from exists_intro _ (dvd_imp_div_mul_eq H))
  (assume H : ∃z, z * x = y,
    obtain (z : ℕ) (zx_eq : z * x = y), from H,
    show x | y, from mul_eq_imp_dvd zx_eq)

theorem dvd_zero {n : ℕ} : n | 0 := sorry
-- (by simp) (dvd_iff_mod_eq_zero n 0)

-- add_rewrite dvd_zero

theorem zero_dvd_iff {n : ℕ} : (0 | n) = (n = 0) := sorry
-- (by simp) (dvd_iff_mod_eq_zero 0 n)

-- add_rewrite zero_dvd_iff

theorem one_dvd {n : ℕ} : 1 | n := sorry
-- (by simp) (dvd_iff_mod_eq_zero 1 n)

-- add_rewrite one_dvd

theorem dvd_self {n : ℕ} : n | n := sorry
-- (by simp) (dvd_iff_mod_eq_zero n n)

-- add_rewrite dvd_self

theorem dvd_mul_self_left {m n : ℕ} : m | (m * n) := sorry
-- (by simp) (dvd_iff_mod_eq_zero m (m * n))

-- add_rewrite dvd_mul_self_left

theorem dvd_mul_self_right {m n : ℕ} : m | (n * m) := sorry
-- (by simp) (dvd_iff_mod_eq_zero m (n * m))

-- add_rewrite dvd_mul_self_left

theorem dvd_trans {m n k : ℕ} (H1 : m | n) (H2 : n | k) : m | k :=
have H3 : n = n div m * m, by simp,
have H4 : k = k div n * (n div m) * m, from
  calc
    k = k div n * n : by simp
      ... = k div n * (n div m * m) : {H3}
      ... = k div n * (n div m) * m : mul_assoc⁻¹,
mp (dvd_iff_exists_mul⁻¹) (exists_intro (k div n * (n div m)) (symm H4))

theorem dvd_add {m n1 n2 : ℕ} (H1 : m | n1) (H2 : m | n2) : m | (n1 + n2) :=
have H : (n1 div m + n2 div m) * m = n1 + n2, by simp,
mp (dvd_iff_exists_mul⁻¹) (exists_intro _ H)

theorem dvd_add_cancel_left {m n1 n2 : ℕ} : m | (n1 + n2) → m | n1 → m | n2 :=
case_zero_pos m
  (assume H1 : 0 | n1 + n2,
    assume H2 : 0 | n1,
    have H3 : n1 + n2 = 0, from subst zero_dvd_iff H1,
    have H4 : n1 = 0, from subst zero_dvd_iff H2,
    have H5 : n2 = 0, from mp (by simp) (subst H4 H3),
    show 0 | n2, by simp)
  (take m,
    assume mpos : m > 0,
    assume H1 : m | (n1 + n2),
    assume H2 : m | n1,
    have H3 : n1 + n2 = n1 + n2 div m * m, from
     calc
       n1 + n2 = (n1 + n2) div m * m : by simp
         ... = (n1 div m * m + n2) div m * m : by simp
         ... = (n2 + n1 div m * m) div m * m : {add_comm}
         ... = (n2 div m + n1 div m) * m : {div_add_mul_self_right mpos}
         ... = n2 div m * m + n1 div m * m : mul_distr_right
         ... = n1 div m * m + n2 div m * m : add_comm
         ... = n1 + n2 div m * m : by simp,
    have H4 : n2 = n2 div m * m, from add_cancel_left H3,
    mp (dvd_iff_exists_mul⁻¹) (exists_intro _ (H4⁻¹)))

theorem dvd_add_cancel_right {m n1 n2 : ℕ} (H : m | (n1 + n2)) : m | n2 → m | n1 :=
dvd_add_cancel_left (add_comm ▸ H)

theorem dvd_sub {m n1 n2 : ℕ} (H1 : m | n1) (H2 : m | n2) : m | (n1 - n2) :=
by_cases
  (assume H3 : n1 ≥ n2,
    have H4 : n1 = n1 - n2 + n2, from (add_sub_ge_left H3)⁻¹,
    show m | n1 - n2, from dvd_add_cancel_right (H4 ▸ H1) H2)
  (assume H3 : ¬ (n1 ≥ n2),
    have H4 : n1 - n2 = 0, from le_imp_sub_eq_zero (lt_imp_le (not_le_imp_gt H3)),
    show m | n1 - n2, from H4⁻¹ ▸ dvd_zero)


-- Gcd and lcm
-- -----------

-- ### definition of gcd

definition gcd_aux_measure (p : ℕ × ℕ) : ℕ :=
pr2 p

definition gcd_aux_rec (p : ℕ × ℕ) (gcd_aux' : ℕ × ℕ → ℕ) : ℕ :=
let x := pr1 p, y := pr2 p in
if y = 0 then x else gcd_aux' (pair y (x mod y))

definition gcd_aux : ℕ × ℕ → ℕ := rec_measure 0 gcd_aux_measure gcd_aux_rec

theorem gcd_aux_decreasing (g1 g2 : ℕ × ℕ → ℕ) (p : ℕ × ℕ)
    (H : ∀p', gcd_aux_measure p' < gcd_aux_measure p → g1 p' = g2 p') :
  gcd_aux_rec p g1 = gcd_aux_rec p g2 :=
let x := pr1 p, y := pr2 p in
let p' := pair y (x mod y) in
let lhs := gcd_aux_rec p g1 in
let rhs := gcd_aux_rec p g2 in
show lhs = rhs, from
  by_cases -- (y = 0)
    (assume H1 : y = 0,
      calc
        lhs = x   : if_pos H1
        ... = rhs : (if_pos H1)⁻¹)
    (assume H1 : y ≠ 0,
      have ypos : y > 0, from ne_zero_imp_pos H1,
      have H2 : gcd_aux_measure p' = x mod y, from pr2_pair _ _,
      have H3 : gcd_aux_measure p' < gcd_aux_measure p, from subst (symm H2) (mod_lt ypos),
      calc
        lhs = g1 p' : if_neg H1
          ... = g2 p' : H _ H3
          ... = rhs : symm (if_neg H1))

theorem gcd_aux_spec (p : ℕ × ℕ) : gcd_aux p =
let x := pr1 p, y := pr2 p in
if y = 0 then x else gcd_aux (pair y (x mod y)) :=
rec_measure_spec gcd_aux_rec gcd_aux_decreasing p

definition gcd (x y : ℕ) : ℕ := gcd_aux (pair x y)

theorem gcd_def (x y : ℕ) : gcd x y = if y = 0 then x else gcd y (x mod y) :=
let x' := pr1 (pair x y), y' := pr2 (pair x y) in
calc
  gcd x y = if y' = 0 then x' else gcd_aux (pair y' (x' mod y'))
      : gcd_aux_spec (pair x y)
    ... = if y = 0 then x else gcd y (x mod y) : rfl

theorem gcd_zero (x : ℕ) : gcd x 0 = x :=
(gcd_def x 0) ⬝ (if_pos rfl)

-- add_rewrite gcd_zero

theorem gcd_pos (m : ℕ) {n : ℕ} (H : n > 0) : gcd m n = gcd n (m mod n) :=
gcd_def m n ⬝ if_neg (pos_imp_ne_zero H)

theorem gcd_zero_left (x : ℕ) : gcd 0 x = x :=
case x (by simp) (take x, (gcd_def _ _) ⬝ (by simp))

-- add_rewrite gcd_zero_left

theorem gcd_induct {P : ℕ → ℕ → Prop} (m n : ℕ) (H0 : ∀m, P m 0)
  (H1 : ∀m n, 0 < n → P n (m mod n) → P m n) : P m n :=
have aux : ∀m, P m n, from
  case_strong_induction_on n H0
    (take n,
      assume IH : ∀k, k ≤ n → ∀m, P m k,
      take m,
      have H2 : m mod succ n ≤ n, from lt_succ_imp_le (mod_lt succ_pos),
      have H3 : P (succ n) (m mod succ n), from IH _ H2 _,
      show P m (succ n), from H1 _ _ succ_pos H3),
aux m

theorem gcd_succ (m n : ℕ) : gcd m (succ n) = gcd (succ n) (m mod succ n) :=
gcd_def _ _ ⬝ if_neg succ_ne_zero

theorem gcd_one (n : ℕ) : gcd n 1 = 1 := sorry
-- (by simp) (gcd_succ n 0)

theorem gcd_self (n : ℕ) : gcd n n = n := sorry
-- case n (by simp) (take n, (by simp) (gcd_succ (succ n) n))

theorem gcd_dvd (m n : ℕ) : (gcd m n | m) ∧ (gcd m n | n) :=
gcd_induct m n
  (take m,
    show (gcd m 0 | m) ∧ (gcd m 0 | 0), by simp)
  (take m n,
    assume npos : 0 < n,
    assume IH : (gcd n (m mod n) | n) ∧ (gcd n (m mod n) | (m mod n)),
    have H : gcd n (m mod n) | (m div n * n + m mod n), from
      dvd_add (dvd_trans (and_elim_left IH) dvd_mul_self_right) (and_elim_right IH),
    have H1 : gcd n (m mod n) | m, from div_mod_eq⁻¹ ▸ H,
    have gcd_eq : gcd n (m mod n) = gcd m n, from symm (gcd_pos _ npos),
    show (gcd m n | m) ∧ (gcd m n | n), from gcd_eq ▸ (and_intro H1 (and_elim_left IH)))

theorem gcd_dvd_left (m n : ℕ) : (gcd m n | m) := and_elim_left (gcd_dvd _ _)

theorem gcd_dvd_right (m n : ℕ) : (gcd m n | n) := and_elim_right (gcd_dvd _ _)

-- add_rewrite gcd_dvd_left gcd_dvd_right

theorem gcd_greatest {m n k : ℕ} : k | m → k | n → k | (gcd m n) :=
gcd_induct m n
  (take m, assume H : k | m, sorry) -- by simp)
  (take m n,
    assume npos : n > 0,
    assume IH : k | n → k | (m mod n) → k | gcd n (m mod n),
    assume H1 : k | m,
    assume H2 : k | n,
    have H3 : k | m div n * n + m mod n, from div_mod_eq ▸ H1,
    have H4 : k | m mod n, from dvd_add_cancel_left H3 (dvd_trans H2 (by simp)),
    have gcd_eq : gcd n (m mod n) = gcd m n, from symm (gcd_pos _ npos),
    show k | gcd m n, from subst gcd_eq (IH H2 H4))

end nat