/-
Copyright (c) 2017 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura
-/
import data.rbtree.basic
universe u

/- TODO(Leo): remove after we cleanup stdlib simp lemmas -/
local attribute [-simp] or.comm or.left_comm or.assoc and.comm and.left_comm and.assoc

namespace rbnode
variables {α : Type u}

@[elab_simple]
lemma find.induction {p : rbnode α → Prop} (lt) [decidable_rel lt]
   (t x)
   (h₁ : p leaf)
   (h₂ : ∀ l y r (h : cmp_using lt x y = ordering.lt) (ih : p l), p (red_node l y r))
   (h₃ : ∀ l y r (h : cmp_using lt x y = ordering.eq),            p (red_node l y r))
   (h₄ : ∀ l y r (h : cmp_using lt x y = ordering.gt) (ih : p r), p (red_node l y r))
   (h₅ : ∀ l y r (h : cmp_using lt x y = ordering.lt) (ih : p l), p (black_node l y r))
   (h₆ : ∀ l y r (h : cmp_using lt x y = ordering.eq),            p (black_node l y r))
   (h₇ : ∀ l y r (h : cmp_using lt x y = ordering.gt) (ih : p r), p (black_node l y r))
   : p t :=
begin
  induction t,
  case leaf {assumption},
  case red_node l y r {
     generalize h : cmp_using lt x y = c,
     cases c,
     case ordering.lt { apply h₂, assumption, assumption },
     case ordering.eq { apply h₃, assumption },
     case ordering.gt { apply h₄, assumption, assumption },
  },
  case black_node l y r {
     generalize h : cmp_using lt x y = c,
     cases c,
     case ordering.lt { apply h₅, assumption, assumption },
     case ordering.eq { apply h₆, assumption },
     case ordering.gt { apply h₇, assumption, assumption },
  }
end

lemma find_correct {t : rbnode α} {lt x} [decidable_rel lt] [is_strict_weak_order α lt] : ∀ {lo hi} (hs : is_searchable lt t lo hi), mem lt x t ↔ ∃ y, find lt t x = some y ∧ x ≈[lt] y :=
begin
  apply find.induction lt t x; intros; simp only [mem, find, *],
  { simp, intro h, cases h with _ h, cases h, contradiction },
  twice { -- red and black cases are identical
    {
      cases hs,
      apply iff.intro,
      {
        intro hm, blast_disjs,
        { exact iff.mp (ih hs₁) hm },
        { simp at h, cases hm, contradiction },
        {
          have hyx : lift lt (some y) (some x) := (range hs₂ hm).1,
          simp [lift] at hyx,
          have hxy : lt x y, { simp [cmp_using] at h, assumption },
          exact absurd (trans_of lt hxy hyx) (irrefl_of lt x)
        }
      },
      { intro hc, left, exact iff.mpr (ih hs₁) hc },
    },
    { simp at h, simp [h, strict_weak_order.equiv], existsi y, split, refl, assumption },
    {
      cases hs,
      apply iff.intro,
      {
        intro hm, blast_disjs,
        {
          have hxy : lift lt (some x) (some y) := (range hs₁ hm).2,
          simp [lift] at hxy,
          have hyx : lt y x, { simp [cmp_using] at h, exact h.2 },
          exact absurd (trans_of lt hxy hyx) (irrefl_of lt x)
        },
        { simp at h, cases hm, contradiction },
        { exact iff.mp (ih hs₂) hm }
      },
      { intro hc, right, right, exact iff.mpr (ih hs₂) hc },
    } }
end

lemma mem_of_mem_exact {lt} [is_irrefl α lt] {x t} : mem_exact x t → mem lt x t :=
begin
  induction t; simp [mem_exact, mem]; intro h,
  all_goals { blast_disjs, simp [ih_1 h], simp [h, irrefl_of lt val], simp [ih_2 h] }
end

lemma find_correct_exact {t : rbnode α} {lt x} [decidable_rel lt] [is_strict_weak_order α lt] : ∀ {lo hi} (hs : is_searchable lt t lo hi), mem_exact x t ↔ find lt t x = some x :=
begin
  apply find.induction lt t x; intros; simp only [mem_exact, find, *],
  { simp, intro h, contradiction },
  twice {
    {
      cases hs,
      apply iff.intro,
      {
        intro hm, blast_disjs,
        { exact iff.mp (ih hs₁) hm },
        { simp at h, subst x, exact absurd h (irrefl y) },
        { have hyx : lift lt (some y) (some x) := (range hs₂ (mem_of_mem_exact hm)).1,
          simp [lift] at hyx,
          have hxy : lt x y, { simp [cmp_using] at h, assumption },
          exact absurd (trans_of lt hxy hyx) (irrefl_of lt x)
        }
      },
      { intro hc, left, exact iff.mpr (ih hs₁) hc },
    },
    { simp at h,
      cases hs,
      apply iff.intro,
      {
        intro hm, blast_disjs,
        { have hxy : lift lt (some x) (some y) := (range hs₁ (mem_of_mem_exact hm)).2,
          simp [lift] at hxy,
          exact absurd hxy h.1 },
        { subst hm },
        { have hyx : lift lt (some y) (some x) := (range hs₂ (mem_of_mem_exact hm)).1,
          simp [lift] at hyx,
          exact absurd hyx h.2 } },
      { intro hm, injection hm, simp [*] } },
    {
      cases hs,
      apply iff.intro,
      {
        intro hm, blast_disjs,
        {
          have hxy : lift lt (some x) (some y) := (range hs₁ (mem_of_mem_exact hm)).2,
          simp [lift] at hxy,
          have hyx : lt y x, { simp [cmp_using] at h, exact h.2 },
          exact absurd (trans_of lt hxy hyx) (irrefl_of lt x)
        },
        { simp at h, subst x, exact absurd h (irrefl y) },
        { exact iff.mp (ih hs₂) hm }
      },
      { intro hc, right, right, exact iff.mpr (ih hs₂) hc } } }
end

lemma eqv_of_find_some {t : rbnode α} {lt x y} [decidable_rel lt] [is_strict_weak_order α lt] : ∀ {lo hi} (hs : is_searchable lt t lo hi) (he : find lt t x = some y), x ≈[lt] y :=
begin
  apply find.induction lt t x; intros; simp only [mem, find, *] at *,
  { contradiction },
  twice {
    { cases hs, exact ih hs₁ rfl },
    { injection he, subst y, simp at h, exact h },
    { cases hs, exact ih hs₂ rfl } }
end

lemma find_eq_find_of_eqv {lt a b} [decidable_rel lt] [is_strict_weak_order α lt] {t : rbnode α} : ∀ {lo hi} (hs : is_searchable lt t lo hi) (heqv : a ≈[lt] b), find lt t a = find lt t b :=
begin
  apply find.induction lt t a; intros; simp [mem, find, strict_weak_order.equiv, *] at *,
  twice {
    { have : lt b y := lt_of_incomp_of_lt heqv.swap h,
      simp [cmp_using, find, *], cases hs, apply ih hs₁ },
    { have := incomp_trans_of lt heqv.swap h, simp [cmp_using, find, *] },
    { have := lt_of_lt_of_incomp h heqv,
      have := not_lt_of_lt this,
      simp [cmp_using, find, *], cases hs, apply ih hs₂ } }
end

end rbnode
