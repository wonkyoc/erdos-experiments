#!/bin/bash

hzs=(30)
#detectors=(efficientdet-d3 efficientdet-d3 efficientdet-d4 efficientdet-d5 efficientdet-d6 efficientdet-d7)
target_speeds=(15 20 25 30)
target_speeds=(15)
file_prefix_name=baseline_1
scenarios=(ERDOSPedestrianBehindCar ERDOSPedestriansBehindCar)
scenarios=(ERDOSPedestriansBehindCar)
#scenarios=(DynamicObjectCrossing_1)

cd ${PYLOT_HOME}
dir_name=results_${file_prefix_name}_30Hz
mkdir -p ${dir_name}

for scenario in ${scenarios[@]}; do
    for run in `seq 11 11`; do
        for hz in ${hzs[@]}; do
            for target_speed in ${target_speeds[@]}; do
                file_base=${dir_name}/${file_prefix_name}_scenario_${scenario}_target_speed_${target_speed}_Hz_${hz}_run_${run}
                if [ ! -f "${PYLOT_HOME}/${file_base}.csv" ]; then
                    echo "[x] Running the experiment with dynamic deadlines, target speed $target_speed"
                    cd ${PYLOT_HOME}/scripts ; ./run_simulator.sh &
                    sleep 10
                    cd $PYLOT_HOME ; python3 pylot.py --flagfile=configs/scenarios/baseline_1.conf --target_speed=$target_speed --log_file_name=$file_base.log --csv_log_file_name=$file_base.csv \
                        --profile_file_name=$file_base.json \
                        --track_file_name=$file_base.track \
                        --obstacle_detection_model_paths=${PYLOT_HOME}/dependencies/models/obstacle_detection/efficientdet/efficientdet-d0/efficientdet-d0_frozen.pb \
                        --obstacle_detection_model_names=efficientdet-d0 \
                        --simulator_fps=$hz --simulator_control_frequency=$hz \
                        --simulator_camera_frequency=30 --simulator_imu_frequency=10 --simulator_localization_frequency=10 &
                    cd $ROOT_SCENARIO_RUNNER ; python3 scenario_runner.py --scenario $scenario --reloadWorld --timeout 600
                    echo "[x] Scenario runner finished. Killing Pylot..."
                    pkill --signal 9 -f scenario_runner.py
                    pkill --signal 9 pylot.py
                    # Kill the simulator
                    `ps aux | grep CarlaUE4 | awk '{print $2}' | head -n -1 | xargs kill -9`
                    `ps aux | grep CarlaUE4 | awk '{print $2}' | tail -n -1 | xargs kill -9`
                    sleep 40
                else
                    echo "$file_base exists"
                fi
            done
        done
    done
done
