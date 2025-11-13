"""Generate a massflash "persist" directory for use by massflash."""

import contextlib
from pathlib import Path

import tarfile
import shutil
import typer
from typing_extensions import Annotated
import tempfile
import subprocess

from pydantic import BaseModel

__version__ = "1.0"


app = typer.Typer()


class GhActionRun(BaseModel):
    conclusion: str
    databaseId: int
    headSha: str
    status: str


def get_last_run() -> GhActionRun:
    """
    Return information about the last completed build from
    <https://github.com/socallinuxexpo/scale-network/actions/workflows/openwrt-build.yml>.
    If the run was not successful, we crash.
    """
    cp = subprocess.run(
        [
            "gh",
            "run",
            "list",
            "--repo=socallinuxexpo/scale-network",
            "--workflow=openwrt-build",
            "--status=completed",
            "--json",
            ",".join(GhActionRun.model_fields.keys()),
            "--limit=1",
            "--jq=.[0]",
        ],
        stdout=subprocess.PIPE,
        text=True,
        check=True,
    )

    run = GhActionRun.model_validate_json(cp.stdout)
    assert run.conclusion == "success"

    return run


@contextlib.contextmanager
def download_artifact(run_id: int, artifact_name: str, expected_filename: str):
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_dir = Path(temp_dir)
        subprocess.run(
            [
                "gh",
                "run",
                "download",
                str(run_id),
                "--repo=socallinuxexpo/scale-network",
                "--name",
                artifact_name,
                "--dir",
                temp_dir,
            ],
            check=True,
        )

        artifact = temp_dir / expected_filename
        assert artifact.exists()
        yield artifact


def extract_file(tarball: tarfile.TarFile, member: str, destination: Path):
    data = tarball.extractfile(member)
    assert data is not None

    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("wb") as f:
        shutil.copyfileobj(data, f)


@app.command()
def main(
    private_key: Annotated[
        Path,
        typer.Argument(
            exists=True,
            dir_okay=False,
        ),
    ],
    out_dir: Annotated[Path, typer.Argument(file_okay=False)],
):
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_dir = Path(temp_dir)
        last_run = get_last_run()

        with download_artifact(
            run_id=last_run.databaseId,
            artifact_name="mt798x-openwrt-build-artifacts",
            expected_filename="mt798x-3dfd1f6-artifacts.tar.gz",
        ) as tarball_path:
            tarball = tarfile.open(tarball_path)
            extract_file(
                tarball,
                "./filogic/openwrt-mediatek-filogic-openwrt_one-squashfs-sysupgrade.itb",
                out_dir / "one" / "flash.bin",
            )

        with download_artifact(
            run_id=last_run.databaseId,
            artifact_name="ath79-openwrt-build-artifacts",
            expected_filename="ath79-3dfd1f6-artifacts.tar.gz",
        ) as tarball_path:
            tarball = tarfile.open(tarball_path)
            extract_file(
                tarball,
                "./generic/openwrt-ath79-generic-netgear_wndr3700-v2-squashfs-sysupgrade.bin",
                out_dir / "wndr3700-v2" / "flash.bin",
            )
            extract_file(
                tarball,
                "./generic/openwrt-ath79-generic-netgear_wndr3800-squashfs-sysupgrade.bin",
                out_dir / "wndr3800" / "flash.bin",
            )
            extract_file(
                tarball,
                "./generic/openwrt-ath79-generic-netgear_wndr3800ch-squashfs-sysupgrade.bin",
                out_dir / "wndr3800ch" / "flash.bin",
            )

        shutil.copy(private_key, out_dir / "id_priv")

        (out_dir / "flash_sha").write_text(last_run.headSha)

        print(f"Done! Successfully populated {out_dir}")


if __name__ == "__main__":  # pragma: no cover
    app()
