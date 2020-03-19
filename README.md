# ACTIVSg200r

A **revised** ACTIVSg200 (`ACTIVSg200r`) synthetic grid (Illinois system) for multi-period analysis (e.g., Unit Commitment, look-ahead dispatch, etc), based on the original ACTIVSg200 system created by Texas A&M folks. All in [Matpower](https://matpower.org/) format.
- System (case/data) files:
	- [`case_ACTIVSg200r.m`](./case_ACTIVSg200r.m): revised ACTIVSg200 casefile, with additional ramping parameters and startup/shutdown cost parameters.
	- [`scenarios_ACTIVSg200.m`](./scenarios_ACTIVSg200.m): load profiles of 365 days in year 2017, (identical to the data in the original `ACTIVSg200` system).
	- [`contab_ACTIVSg200.m`](./contab_ACTIVSg200.m): contingency table, (identical to the data in the original `ACTIVSg200` system).
	- [`xgd_ACTIVSg200r.m`](./xgd_ACTIVSg200r.m): additional generator data (minup, mindown time, initial status).
	- [`scenarios.mat`](./scenarios.mat): a table saving all scenarios, identical as the `chgtab` matrix in `scenarios_ACTIVSg200.m`.
	- [`ACTIVSg200r-InitialState.mat`](./ACTIVSg200r-InitialState.mat): initial states of generators (for t=0, day 1), obtained by solving a single-snapshot UC (t=1, day 1).
	- [`gendata_ACTIVSg200r.mat`](./gendata_ACTIVSg200r.mat): used in `xgd_ACTIVSg200r.m`, `minup` and `mindown` data.
- Additional scripts:
	- [`revise_ACTIVSg200.m`](./revise_ACTIVSg200.m): how additional parameters are chosen, and create the `ACTIVSg200r` case.
	- [`run_SCUC.m`](./run_SCUC.m): a short script of solving SCUC for `ACTIVSg200r` using [MOST](https://matpower.org/doc/manuals/).
	
## About the Original System `ACTIVSg200`

- Details about the original system `ACTIVSg200` can be found at [Illinois 200-Bus System: ACTIVSg200](https://electricgrids.engr.tamu.edu/electric-grid-test-cases/activsg200/)
- A description of the initial algorithm used to develop these cases is given in: [1].

## About the Revised System `ACTIVSg200r`

The following changes have been made to `ACTIVSg200`:

1.  assign values of ZONE to BUS_AREA of mpc.bus

2.  adding the following missing parameters
   
   - missing MIN-ON time, MIN-OFF time
   - missing startup/shutdown cost
   - missing ramping parameters: RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q

   Range of parameters are from reference [2]. Details of how those parameters are chosen are in [`revise_ACTIVSg200r.m`](./revise_ACTiVSg200r.m)

## References

[1] A. B. Birchfield; T. Xu; K. M. Gegner; K. S. Shetye; T. J. Overbye, “[Grid Structural Characteristics as Validation Criteria for Synthetic Networks](https://urldefense.proofpoint.com/v2/url?u=http-3A__ieeexplore.ieee.org_document_7725528_&d=DwMFAg&c=8hUWFZcy2Z-Za5rBPlktOQ&r=BaZP1q9WdgzAzUtYfK1vHbhZiO0i6RX2AEHJekfHTdI&m=9Bcj8G73DDdx0c3ZTxV6CFrGxmHkzlDHNJ4K5zXn7UU&s=KyLZLQql3Eo5C0fRRizk1gPXh7uPgn7I9kvMcTQD9OU&e=),”  in *[IEEE Transactions on Power Systems](http://ieeexplore.ieee.org/xpl/RecentIssue.jsp?punumber=59),* vol. 32, no. 4, pp. 3258-3265, July 2017.

[2] T. Xu, A. B. Birchfield, K. M. Gegner, K. S. Shetye, and T. J. Overbye, “Application of large-scale synthetic power system models for energy economic studies,” in Proceedings of the 50th Hawaii International Conference on System Sciences, 2017.

Speical thanks to friends and colleagues in Texas A&M University for creating the original system (and many others)!