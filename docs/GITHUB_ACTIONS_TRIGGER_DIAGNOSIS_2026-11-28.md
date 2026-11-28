# GitHub Actions trigger diagnosis — 2026-11-28

## Scope
Read-only diagnosis of why the latest PR #67 head has no associated GitHub Actions run. No workflow dispatch, repository settings change, or default-branch change was attempted.

## Confirmed facts
- PR #67 is open, Draft, unmerged, and targets `main`.
- The workflow `.github/workflows/exact-decimal-tests.yml` exists on `main` (blob `358f8009deb51d789fc85404b7887e4264a3c3ba`) and on the PR branch. Therefore, the simple explanation that the workflow file is absent from the base branch is **not** correct.
- The workflow declares `pull_request: branches: [main]`, so the PR's base branch matches its configured target.
- Historical runs for PR #67 exist and completed successfully:
  - run `46036165275`, head `e04901bbeaca047742baeff677517934bb9123cc`
  - run `46037695694`, head `776802892afc80b164e8b7907333df775e8b1e8a`
  - run `46038127085`, head `e7e33a1b1fea07f8d40a136e148225eb8777e7ae`
  - run `46038710233`, head `966a7ce00e560b200fb7fc3ab3c4cc8976047935`
  - run `46038816951`, head `ce83b53610e7daea12fbc927b7d1ca214486696d`
- Those successful runs are historical and do not establish that the latest head was tested.
- For latest checked head `c2bb944c2ccbe64e92c3520549933c7e2186ef57`, the commit check-runs endpoint returned zero checks and the Actions runs endpoint filtered by `head_sha` returned zero runs.
- The GitHub tool surface exposes job-log/step inspection and rerun of failed jobs, but no workflow-dispatch or create-run action. There is no failed run to rerun.

## Diagnosis
The absence of a latest-head run is confirmed; its cause is **not yet established**. The workflow exists on the base branch and the PR base matches its `pull_request` filter, so do not attribute the issue to either of those. Possible causes outside the available evidence include event delivery/trigger suppression for the credential used to update the branch, repository Actions policy, or a GitHub-side event issue. None is asserted as fact.

## Safe next diagnostic
The repository owner should inspect the repository's Actions page and workflow state/permissions, and check the PR timeline for a `synchronize` event after the latest commit. If GitHub did not deliver the event, a normal owner-authenticated push or an explicitly approved workflow-dispatch mechanism can be considered. Do not change default-branch workflow files, repository Actions permissions, or branch protections without explicit owner approval.

## Safety
No repository settings, workflow files on `main`, branch protections, Production resources, database, or financial data were changed. No workflow run was fabricated or claimed.
