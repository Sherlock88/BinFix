(set-logic QF_AUFBV )
(set-option :produce-unsat-cores true)
(declare-fun v0_sym_eax_0 () (Array (_ BitVec 32) (_ BitVec 8) ) )
(assert (! (bvslt  (concat  (select  v0_sym_eax_0 (_ bv3 32) ) (concat  (select  v0_sym_eax_0 (_ bv2 32) ) (concat  (select  v0_sym_eax_0 (_ bv1 32) ) (select  v0_sym_eax_0 (_ b$
(assert (! true :named a1) )
(check-sat)
(get-unsat-core)
(exit)
